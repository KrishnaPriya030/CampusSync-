
package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;

import org.json.JSONObject;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.exception.PaymentReservationExpiredException;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.Utils;

@Service
public class RazorpayPaymentVerificationService {

    private final PaymentRepository paymentRepository;
    private final EventRegistrationRepository registrationRepository;
    private final NotificationService notificationService;
    private final RazorpayClient razorpayClient;

    public RazorpayPaymentVerificationService(
            PaymentRepository paymentRepository,
            EventRegistrationRepository registrationRepository,
            NotificationService notificationService,
            RazorpayClient razorpayClient) {

        this.paymentRepository = paymentRepository;
        this.registrationRepository = registrationRepository;
        this.notificationService = notificationService;
        this.razorpayClient = razorpayClient;
    }

    @Transactional(noRollbackFor = PaymentReservationExpiredException.class)
    public void verifyPayment(
            Long userId,
            String razorpayOrderId,
            String razorpayPaymentId,
            String razorpaySignature) {

        // 1. Validate input.

        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "A valid authenticated user is required");
        }

        if (razorpayOrderId == null || razorpayOrderId.isBlank()
                || razorpayPaymentId == null || razorpayPaymentId.isBlank()
                || razorpaySignature == null || razorpaySignature.isBlank()) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Razorpay order ID, payment ID, and signature are required");
        }

        // 2. Find the payment record.

        Payment initialPayment = paymentRepository
                .findByRazorpayOrderId(razorpayOrderId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Payment record not found for this order"));

        if (initialPayment.getRegistration() == null
                || initialPayment.getRegistration().getId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Payment has no valid registration");
        }

        Long registrationId = initialPayment.getRegistration().getId();

        // 3. Lock registration first, then payment.

        EventRegistration registration = registrationRepository
                .findByIdForUpdate(registrationId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Registration not found"));

        Payment payment = paymentRepository
                .findByRazorpayOrderIdForUpdate(razorpayOrderId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Payment record not found for this order"));

        if (payment.getRegistration() == null
                || !registrationId.equals(payment.getRegistration().getId())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Payment does not match the expected registration");
        }

        // 4. Verify ownership.

        if (registration.getStudent() == null
                || registration.getStudent().getUser() == null
                || registration.getStudent().getUser().getId() == null
                || !registration.getStudent().getUser().getId().equals(userId)) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "You can verify only your own payment");
        }

        if (payment.getStatus() == PaymentStatus.REFUND_PENDING
                || payment.getStatus() == PaymentStatus.REFUNDED) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "This payment is currently in a refund state");
        }

        // 5. Verify the Razorpay signature.

        String secret = System.getenv("RAZORPAY_KEY_SECRET");

        if (secret == null || secret.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Razorpay secret is not configured");
        }

        try {
            String payload = razorpayOrderId + "|" + razorpayPaymentId;

            boolean validSignature = Utils.verifySignature(
                    payload,
                    razorpaySignature,
                    secret);

            if (!validSignature) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Invalid Razorpay payment signature");
            }
        } catch (ResponseStatusException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Unable to verify the Razorpay payment signature",
                    exception);
        }

        // 6. Validate the actual Razorpay order.

        final JSONObject gatewayOrder;

        try {
            Order fetchedOrder = razorpayClient.orders.fetch(razorpayOrderId);
            gatewayOrder = fetchedOrder.toJson();
        } catch (Exception exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Unable to retrieve the Razorpay order",
                    exception);
        }

        if (!razorpayOrderId.equals(gatewayOrder.optString("id", ""))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "The fetched Razorpay order ID is invalid");
        }

        if (!"INR".equalsIgnoreCase(
                gatewayOrder.optString("currency", ""))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "The Razorpay order currency is invalid");
        }

        long expectedAmountPaise = toPaise(payment.getAmount());

        if (gatewayOrder.optLong("amount", -1) != expectedAmountPaise) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "The Razorpay order amount does not match the stored amount");
        }

        String expectedReceipt = "CAMPUS_"
                + registration.getEvent().getId()
                + "_"
                + registration.getStudent().getId()
                + "_"
                + registration.getId();

        if (!expectedReceipt.equals(gatewayOrder.optString("receipt", ""))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "The Razorpay order receipt does not match this registration");
        }

        // 7. Fetch and validate the actual Razorpay payment.

        final JSONObject gatewayPayment;

        try {
            com.razorpay.Payment fetchedPayment =
                    razorpayClient.payments.fetch(razorpayPaymentId);

            gatewayPayment = fetchedPayment.toJson();
        } catch (Exception exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Unable to retrieve payment details from Razorpay",
                    exception);
        }

        if (!razorpayOrderId.equals(
                gatewayPayment.optString("order_id", ""))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "The Razorpay payment does not belong to this order");
        }

        if (!"INR".equalsIgnoreCase(
                gatewayPayment.optString("currency", ""))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "The Razorpay payment currency is invalid");
        }

        if (gatewayPayment.optLong("amount", -1) != expectedAmountPaise) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "The Razorpay payment amount does not match the stored amount");
        }

        boolean captured = "captured".equalsIgnoreCase(
                gatewayPayment.optString("status", ""));

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime expiry = registration.getPaymentExpiresAt();

        // 8. Handle repeated verification safely.

        if (payment.getStatus() == PaymentStatus.PAID) {

            if (!razorpayPaymentId.equals(payment.getRazorpayPaymentId())) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "This order has already been recorded with another payment ID");
            }

            if (registration.getStatus()
                    == EventRegistrationStatus.REGISTERED) {
                return;
            }

            if (registration.getStatus()
                    == EventRegistrationStatus.CANCELLED) {
                throw new PaymentReservationExpiredException();
            }

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "The payment is recorded as paid, but the registration requires reconciliation");
        }

        // 9. Handle an uncaptured payment after expiry.

        boolean expired = expiry == null || !now.isBefore(expiry);

        if (!captured) {

            if (expired
                    && registration.getStatus()
                            == EventRegistrationStatus.PAYMENT_PENDING) {

                payment.setStatus(PaymentStatus.FAILED);
                payment.setUpdatedAt(now);
                paymentRepository.save(payment);

                registration.setStatus(EventRegistrationStatus.CANCELLED);
                registration.setPaymentExpiresAt(null);
                registrationRepository.save(registration);

                try {
                    notificationService.createNotification(
                            userId,
                            "Payment Reservation Expired",
                            "Your payment reservation for event \""
                                    + registration.getEvent().getTitle()
                                    + "\" expired before payment was captured. "
                                    + "Your registration was cancelled.",
                            NotificationType.PAYMENT_FAILED,
                            registration.getEvent());
                } catch (RuntimeException exception) {
                    // Log and monitor notification failure separately.
                    // Do not let it undo the reservation expiry.
                    org.slf4j.LoggerFactory
                            .getLogger(RazorpayPaymentVerificationService.class)
                            .error(
                                    "Failed to notify student {} about expired registration {}",
                                    userId,
                                    registrationId,
                                    exception);
                }

                throw new PaymentReservationExpiredException();
            }

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Razorpay has not captured this payment. Registration is not confirmed.");
        }

        // 10. A captured payment after expiry must not confirm registration.

        if (expired
                || registration.getStatus()
                        != EventRegistrationStatus.PAYMENT_PENDING) {

            payment.setRazorpayPaymentId(razorpayPaymentId);
            payment.setRazorpaySignature(razorpaySignature);
            payment.setStatus(PaymentStatus.PAID);
            payment.setPaidAt(now);
            payment.setUpdatedAt(now);
            paymentRepository.save(payment);

            registration.setStatus(EventRegistrationStatus.CANCELLED);
            registration.setPaymentExpiresAt(null);
            registrationRepository.save(registration);

            try {
                notificationService.createNotification(
                        userId,
                        "Payment Received - Registration Not Confirmed",
                        "Razorpay captured your payment for event \""
                                + registration.getEvent().getTitle()
                                + "\", but your reservation expired or is no longer active. "
                                + "Your registration has not been confirmed. "
                                + "Please contact the event organizer regarding the payment.",
                        NotificationType.PAYMENT_SUCCESS,
                        registration.getEvent());
            } catch (RuntimeException exception) {
                org.slf4j.LoggerFactory
                        .getLogger(RazorpayPaymentVerificationService.class)
                        .error(
                                "Failed to notify student {} about late captured payment for registration {}",
                                userId,
                                registrationId,
                                exception);
            }

            // The exception is excluded from rollback by the transaction annotation.
            throw new PaymentReservationExpiredException();
        }

        // 11. Confirm a valid, timely payment.

        payment.setRazorpayPaymentId(razorpayPaymentId);
        payment.setRazorpaySignature(razorpaySignature);
        payment.setStatus(PaymentStatus.PAID);
        payment.setPaidAt(now);
        payment.setUpdatedAt(now);
        paymentRepository.save(payment);

        registration.setStatus(EventRegistrationStatus.REGISTERED);
        registration.setConfirmedAt(now);
        registration.setPaymentExpiresAt(null);
        registrationRepository.save(registration);

        // 12. Notify the student. Notification failure must not undo payment state.

        try {
            notificationService.createNotification(
                    userId,
                    "Payment Successful",
                    "Your payment for event \""
                            + registration.getEvent().getTitle()
                            + "\" was successful.",
                    NotificationType.PAYMENT_SUCCESS,
                    registration.getEvent());

            notificationService.createNotification(
                    userId,
                    "Registration Confirmed",
                    "You are successfully registered for event \""
                            + registration.getEvent().getTitle()
                            + "\".",
                    NotificationType.REGISTRATION_CONFIRMED,
                    registration.getEvent());
        } catch (RuntimeException exception) {
            org.slf4j.LoggerFactory
                    .getLogger(RazorpayPaymentVerificationService.class)
                    .error(
                            "Payment verified but notification failed for registration {}",
                            registrationId,
                            exception);
        }
    }

    private long toPaise(BigDecimal amount) {

        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "The stored payment amount is missing or invalid");
        }

        try {
            return amount
                    .setScale(2, RoundingMode.UNNECESSARY)
                    .multiply(BigDecimal.valueOf(100))
                    .longValueExact();
        } catch (ArithmeticException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "The stored payment amount is invalid",
                    exception);
        }
    }
}
