
package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;

@Service
public class PaymentReservationExpiryService {

    private static final Logger log =
            LoggerFactory.getLogger(PaymentReservationExpiryService.class);

    private final EventRegistrationRepository registrationRepository;
    private final PaymentRepository paymentRepository;
    private final NotificationService notificationService;
    private final RazorpayClient razorpayClient;
    private final TransactionTemplate transactionTemplate;

    public PaymentReservationExpiryService(
            EventRegistrationRepository registrationRepository,
            PaymentRepository paymentRepository,
            NotificationService notificationService,
            RazorpayClient razorpayClient,
            PlatformTransactionManager transactionManager) {

        this.registrationRepository = registrationRepository;
        this.paymentRepository = paymentRepository;
        this.notificationService = notificationService;
        this.razorpayClient = razorpayClient;
        this.transactionTemplate =
                new TransactionTemplate(transactionManager);
    }

    /**
     * Runs every 60 seconds.
     *
     * Each reservation is processed independently. Database transactions
     * are not held open while contacting Razorpay.
     */
    @Scheduled(fixedRate = 60000)
    public void expirePaymentReservations() {

        LocalDateTime now = LocalDateTime.now();

        List<EventRegistration> candidates =
                registrationRepository
                        .findByStatusAndPaymentExpiresAtLessThanEqual(
                                EventRegistrationStatus.PAYMENT_PENDING,
                                now);

        List<Long> registrationIds = new ArrayList<>();

        for (EventRegistration candidate : candidates) {
            if (candidate.getId() != null) {
                registrationIds.add(candidate.getId());
            }
        }

        for (Long registrationId : registrationIds) {
            try {
                processReservation(registrationId, now);
            } catch (RuntimeException exception) {
                log.error(
                        "Failed to process expired reservation {}. "
                                + "It will be retried by a later scheduler run.",
                        registrationId,
                        exception);
            }
        }
    }

    private void processReservation(
            Long registrationId,
            LocalDateTime now) {

        /*
         * Read the necessary information in a short transaction.
         * No database locks are held while Razorpay is contacted.
         */
        ReservationSnapshot snapshot = transactionTemplate.execute(
                transactionStatus ->
                        loadSnapshot(registrationId, now));

        if (snapshot == null) {
            return;
        }

        /*
         * Do not automatically reactivate a registration just because
         * its local payment says PAID. That inconsistent state requires
         * reconciliation.
         */
        if (snapshot.paymentStatus == PaymentStatus.PAID) {
            log.error(
                    "Registration {} is PAYMENT_PENDING but its local payment "
                            + "is PAID. Deferring to reconciliation.",
                    registrationId);
            return;
        }

        /*
         * Only PENDING or FAILED payments can proceed through this
         * expiry check. Refund-related and unknown states are deferred.
         */
        if (snapshot.paymentStatus != PaymentStatus.PENDING
                && snapshot.paymentStatus != PaymentStatus.FAILED) {

            log.warn(
                    "Deferring reservation {} because payment status is {}.",
                    registrationId,
                    snapshot.paymentStatus);
            return;
        }

        GatewayResult gatewayResult = checkGateway(snapshot);

        if (!gatewayResult.reliable) {
            log.warn(
                    "Deferring reservation {} because the Razorpay outcome "
                            + "could not be established reliably.",
                    registrationId);
            return;
        }

        /*
         * Apply the gateway result in a new short transaction.
         * Lock the registration first and payment second.
         */
        NotificationRequest notification = transactionTemplate.execute(
                transactionStatus ->
                        applyGatewayResult(
                                registrationId,
                                now,
                                gatewayResult));

        /*
         * Notifications are attempted after the payment-state transaction
         * commits. Notification failure therefore cannot undo that state.
         */
        if (notification != null) {
            sendNotificationSafely(registrationId, notification);
        }
    }

    private ReservationSnapshot loadSnapshot(
            Long registrationId,
            LocalDateTime now) {

        EventRegistration registration =
                registrationRepository.findById(registrationId)
                        .orElse(null);

        if (registration == null
                || registration.getStatus()
                        != EventRegistrationStatus.PAYMENT_PENDING) {
            return null;
        }

        LocalDateTime expiry = registration.getPaymentExpiresAt();

        if (expiry == null || expiry.isAfter(now)) {
            return null;
        }

        Payment payment = paymentRepository
                .findByRegistrationId(registrationId)
                .orElse(null);

        if (payment == null) {
            log.error(
                    "Reservation {} has no associated payment record. "
                            + "Automatic expiry is deferred.",
                    registrationId);
            return null;
        }

        if (payment.getAmount() == null) {
            log.error(
                    "Payment amount is missing for reservation {}.",
                    registrationId);
            return null;
        }

        try {
            long amountInPaise = toPaise(payment.getAmount());

            return new ReservationSnapshot(
                    registrationId,
                    registration.getEvent().getId(),
                    registration.getStudent().getId(),
                    payment.getRazorpayOrderId(),
                    payment.getStatus(),
                    amountInPaise,
                    buildReceipt(registration));

        } catch (RuntimeException exception) {
            log.error(
                    "Could not prepare reservation {} for reconciliation.",
                    registrationId,
                    exception);
            return null;
        }
    }

    private GatewayResult checkGateway(ReservationSnapshot snapshot) {

        try {
            String orderId = snapshot.orderId;

            /*
             * Recover an order whose ID was not saved locally.
             * If receipt lookup cannot find an order, we defer expiry:
             * the result is not sufficiently conclusive to cancel safely.
             */
            if (orderId == null || orderId.isBlank()) {

                JSONObject params = new JSONObject();
                params.put("receipt", snapshot.receipt);
                params.put("count", 100);

                List<Order> orders =
                        razorpayClient.orders.fetchAll(params);

                Order matchingOrder = null;

                for (Order candidate : orders) {

                    String candidateReceipt =
                            stringValue(candidate.get("receipt"));

                    if (!snapshot.receipt.equals(candidateReceipt)) {
                        continue;
                    }

                    if (matchingOrder != null) {
                        log.error(
                                "Multiple Razorpay orders found for receipt {}.",
                                snapshot.receipt);
                        return GatewayResult.uncertain();
                    }

                    matchingOrder = candidate;
                }

                if (matchingOrder == null) {
                    return GatewayResult.uncertain();
                }

                orderId = stringValue(matchingOrder.get("id"));
            }

            if (orderId == null || orderId.isBlank()) {
                return GatewayResult.uncertain();
            }

            Order order = razorpayClient.orders.fetch(orderId);

            if (!orderId.equals(stringValue(order.get("id")))
                    || !snapshot.receipt.equals(
                            stringValue(order.get("receipt")))
                    || !"INR".equalsIgnoreCase(
                            stringValue(order.get("currency")))) {

                log.error(
                        "Razorpay order validation failed for reservation {}.",
                        snapshot.registrationId);
                return GatewayResult.uncertain();
            }

            Object orderAmount = order.get("amount");

            if (!(orderAmount instanceof Number)
                    || ((Number) orderAmount).longValue()
                            != snapshot.amountInPaise) {

                log.error(
                        "Razorpay order amount mismatch for reservation {}.",
                        snapshot.registrationId);
                return GatewayResult.uncertain();
            }

            List<com.razorpay.Payment> gatewayPayments =
                    razorpayClient.orders.fetchPayments(orderId);

            String capturedPaymentId = null;

            for (com.razorpay.Payment gatewayPayment : gatewayPayments) {

                String gatewayOrderId =
                        stringValue(gatewayPayment.get("order_id"));

                String currency =
                        stringValue(gatewayPayment.get("currency"));

                Object amount = gatewayPayment.get("amount");

                if (!orderId.equals(gatewayOrderId)
                        || !"INR".equalsIgnoreCase(currency)
                        || !(amount instanceof Number)
                        || ((Number) amount).longValue()
                                != snapshot.amountInPaise) {

                    return GatewayResult.uncertain();
                }

                String status =
                        stringValue(gatewayPayment.get("status"));

                Object capturedValue =
                        gatewayPayment.get("captured");

                boolean captured =
                        Boolean.TRUE.equals(capturedValue)
                                || "true".equalsIgnoreCase(
                                        stringValue(capturedValue))
                                || "captured".equalsIgnoreCase(status);

                if (captured) {

                    String paymentId =
                            stringValue(gatewayPayment.get("id"));

                    if (paymentId == null
                            || paymentId.isBlank()
                            || capturedPaymentId != null) {

                        // Multiple captured payments need manual review.
                        return GatewayResult.uncertain();
                    }

                    capturedPaymentId = paymentId;

                } else if ("authorized".equalsIgnoreCase(status)
                        || "created".equalsIgnoreCase(status)
                        || "pending".equalsIgnoreCase(status)) {

                    // The payment may still progress to capture.
                    return GatewayResult.uncertain();
                }
            }

            if (capturedPaymentId != null) {
                return GatewayResult.captured(capturedPaymentId);
            }

            return GatewayResult.noCapturedPayment();

        } catch (Exception exception) {
            log.warn(
                    "Unable to reconcile Razorpay for reservation {}.",
                    snapshot.registrationId,
                    exception);

            return GatewayResult.uncertain();
        }
    }

    private NotificationRequest applyGatewayResult(
            Long registrationId,
            LocalDateTime now,
            GatewayResult gatewayResult) {

        EventRegistration registration =
                registrationRepository
                        .findByIdForUpdate(registrationId)
                        .orElse(null);

        if (registration == null
                || registration.getStatus()
                        != EventRegistrationStatus.PAYMENT_PENDING) {
            return null;
        }

        LocalDateTime expiry = registration.getPaymentExpiresAt();

        if (expiry == null || expiry.isAfter(now)) {
            return null;
        }

        Payment payment = paymentRepository
                .findByRegistrationIdForUpdate(registrationId)
                .orElse(null);

        if (payment == null) {
            log.error(
                    "Payment record disappeared for reservation {}.",
                    registrationId);
            return null;
        }

        /*
         * Recheck local payment state after acquiring locks.
         * Another request may have verified the payment while Razorpay
         * was being queried.
         */
        if (payment.getStatus() == PaymentStatus.PAID) {
            log.error(
                    "Reservation {} became locally PAID during reconciliation. "
                            + "Leaving registration unchanged.",
                    registrationId);
            return null;
        }

        if (payment.getStatus() != PaymentStatus.PENDING
                && payment.getStatus() != PaymentStatus.FAILED) {
            log.warn(
                    "Reservation {} now has payment status {}. "
                            + "Deferring expiry.",
                    registrationId,
                    payment.getStatus());
            return null;
        }

        if (gatewayResult.capturedPaymentId != null) {

            String existingPaymentId = payment.getRazorpayPaymentId();

            if (existingPaymentId != null
                    && !existingPaymentId.isBlank()
                    && !existingPaymentId.equals(
                            gatewayResult.capturedPaymentId)) {

                log.error(
                        "Razorpay payment ID conflicts with local data for "
                                + "reservation {}. Manual reconciliation required.",
                        registrationId);
                return null;
            }

            payment.setStatus(PaymentStatus.PAID);
            payment.setRazorpayPaymentId(
                    gatewayResult.capturedPaymentId);
            payment.setPaidAt(now);
            payment.setUpdatedAt(now);
            paymentRepository.save(payment);

            /*
             * The reservation has expired. Record the captured payment
             * without automatically reactivating the registration.
             */
            registration.setStatus(EventRegistrationStatus.CANCELLED);
            registration.setPaymentExpiresAt(null);
            registrationRepository.save(registration);

            log.warn(
                    "Late captured payment recorded for reservation {}. "
                            + "Registration remains CANCELLED.",
                    registrationId);

            return new NotificationRequest(
                    "Payment Received - Registration Not Confirmed",
                    "Razorpay captured your payment for event \""
                            + registration.getEvent().getTitle()
                            + "\", but your reservation expired. "
                            + "Your registration remains cancelled. "
                            + "Please contact the event organizer "
                            + "regarding the payment.",
                    NotificationType.PAYMENT_SUCCESS);
        }

        // The gateway check was reliable and found no captured or
        // unresolved payment for this order.
        if (payment.getStatus() == PaymentStatus.PENDING) {
            payment.setStatus(PaymentStatus.FAILED);
            payment.setUpdatedAt(now);
            paymentRepository.save(payment);
        }

        registration.setStatus(EventRegistrationStatus.CANCELLED);
        registration.setPaymentExpiresAt(null);
        registrationRepository.save(registration);

        log.info("Expired unpaid reservation {}.", registrationId);

        return new NotificationRequest(
                "Payment Reservation Expired",
                "Your payment reservation for event \""
                        + registration.getEvent().getTitle()
                        + "\" expired without a confirmed payment. "
                        + "Your registration was cancelled.",
                NotificationType.PAYMENT_FAILED);
    }

    private void sendNotificationSafely(
            Long registrationId,
            NotificationRequest notification) {

        try {
            /*
             * Run notification creation in its own transaction, after the
             * payment-state transaction has already completed.
             */
            transactionTemplate.executeWithoutResult(transactionStatus -> {

                EventRegistration registration =
                        registrationRepository.findById(registrationId)
                                .orElse(null);

                if (registration == null
                        || registration.getStudent() == null
                        || registration.getStudent().getUser() == null
                        || registration.getStudent().getUser().getId() == null) {

                    log.error(
                            "Cannot notify student for registration {}: "
                                    + "student/user relationship is missing.",
                            registrationId);
                    return;
                }

                notificationService.createNotification(
                        registration.getStudent().getUser().getId(),
                        notification.title,
                        notification.message,
                        notification.type,
                        registration.getEvent());
            });

        } catch (RuntimeException exception) {
            log.error(
                    "Notification failed for registration {}. "
                            + "Payment-state changes remain committed.",
                    registrationId,
                    exception);
        }
    }

    private String buildReceipt(EventRegistration registration) {

        return "CAMPUS_"
                + registration.getEvent().getId()
                + "_"
                + registration.getStudent().getId()
                + "_"
                + registration.getId();
    }

    private long toPaise(BigDecimal amount) {

        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException(
                    "Payment amount must be positive");
        }

        return amount
                .setScale(2, RoundingMode.UNNECESSARY)
                .multiply(BigDecimal.valueOf(100))
                .longValueExact();
    }

    private String stringValue(Object value) {
        return value == null ? null : value.toString();
    }

    private static final class ReservationSnapshot {

        private final Long registrationId;
        private final Long eventId;
        private final Long studentId;
        private final String orderId;
        private final PaymentStatus paymentStatus;
        private final long amountInPaise;
        private final String receipt;

        private ReservationSnapshot(
                Long registrationId,
                Long eventId,
                Long studentId,
                String orderId,
                PaymentStatus paymentStatus,
                long amountInPaise,
                String receipt) {

            this.registrationId = registrationId;
            this.eventId = eventId;
            this.studentId = studentId;
            this.orderId = orderId;
            this.paymentStatus = paymentStatus;
            this.amountInPaise = amountInPaise;
            this.receipt = receipt;
        }
    }

    private static final class GatewayResult {

        private final boolean reliable;
        private final String capturedPaymentId;

        private GatewayResult(
                boolean reliable,
                String capturedPaymentId) {

            this.reliable = reliable;
            this.capturedPaymentId = capturedPaymentId;
        }

        static GatewayResult captured(String paymentId) {
            return new GatewayResult(true, paymentId);
        }

        static GatewayResult noCapturedPayment() {
            return new GatewayResult(true, null);
        }

        static GatewayResult uncertain() {
            return new GatewayResult(false, null);
        }
    }

    private static final class NotificationRequest {

        private final String title;
        private final String message;
        private final NotificationType type;

        private NotificationRequest(
                String title,
                String message,
                NotificationType type) {

            this.title = title;
            this.message = message;
            this.type = type;
        }
    }
}
