
package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReentrantLock;

import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.server.ResponseStatusException;

import com.campussync.campussync_backend.dto.RazorpayOrderResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.campussync.campussync_backend.repository.StudentRepository;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;

@Service
public class PaidEventRegistrationService {

    private static final org.slf4j.Logger log =
            org.slf4j.LoggerFactory.getLogger(
                    PaidEventRegistrationService.class);

    /*
     * Coordinates order creation for the same registration within this
     * JVM. This is not a distributed lock; multiple backend instances
     * require a database-backed order-creation claim.
     */
    private static final ConcurrentHashMap<Long, ReentrantLock> ORDER_LOCKS =
            new ConcurrentHashMap<>();

    private final EventRepository eventRepository;
    private final StudentRepository studentRepository;
    private final EventRegistrationRepository registrationRepository;
    private final PaymentRepository paymentRepository;
    private final RazorpayClient razorpayClient;
    private final TransactionTemplate transactionTemplate;

    @Value("${razorpay.key.id}")
    private String razorpayKeyId;

    public PaidEventRegistrationService(
            EventRepository eventRepository,
            StudentRepository studentRepository,
            EventRegistrationRepository registrationRepository,
            PaymentRepository paymentRepository,
            RazorpayClient razorpayClient,
            PlatformTransactionManager transactionManager) {

        this.eventRepository = eventRepository;
        this.studentRepository = studentRepository;
        this.registrationRepository = registrationRepository;
        this.paymentRepository = paymentRepository;
        this.razorpayClient = razorpayClient;
        this.transactionTemplate =
                new TransactionTemplate(transactionManager);
    }

    /**
     * Creates a durable local reservation before contacting Razorpay.
     * Simultaneous requests for the same registration are serialized
     * within this backend process.
     */
    public RazorpayOrderResponse createOrder(Long userId, Long eventId) {

        validateInput(userId, eventId);

        Reservation initialReservation = transactionTemplate.execute(
                transactionStatus -> prepareReservation(userId, eventId));

        if (initialReservation == null) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Unable to prepare the payment reservation");
        }

        ReentrantLock lock = ORDER_LOCKS.computeIfAbsent(
                initialReservation.registrationId,
                ignored -> new ReentrantLock());

        lock.lock();

        try {
            /*
             * Refresh the reservation after acquiring the lock.
             * Another request in this JVM may have saved the order ID
             * while this request was waiting.
             */
            Reservation reservation = transactionTemplate.execute(
                    transactionStatus ->
                            prepareReservation(userId, eventId));

            if (reservation == null) {
                throw new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "Unable to reload the payment reservation");
            }

            if (!initialReservation.registrationId.equals(
                    reservation.registrationId)) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "The active registration changed during order creation");
            }

            return createOrderForReservation(reservation);

        } finally {
            lock.unlock();
        }
    }

    private RazorpayOrderResponse createOrderForReservation(
            Reservation reservation) {

        // Reuse a previously persisted order only if the reservation is active.
        if (reservation.orderId != null
                && !reservation.orderId.isBlank()) {

            if (reservation.expired) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "The payment reservation has expired");
            }

            return toResponse(reservation, reservation.orderId);
        }

        /*
         * Search before creating an order. This can recover an order
         * created at Razorpay when saving its ID locally failed.
         */
        Order order = findOrderByReceipt(
                reservation.receipt,
                reservation.amountInPaise);

        if (order == null) {

            if (reservation.expired) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "The payment reservation has expired. "
                                + "Any existing Razorpay order must be reconciled.");
            }

            try {
                JSONObject request = new JSONObject();
                request.put("amount", reservation.amountInPaise);
                request.put("currency", "INR");
                request.put("receipt", reservation.receipt);

                order = razorpayClient.orders.create(request);

            } catch (RazorpayException createException) {

                /*
                 * The network may fail after Razorpay has created the order.
                 * Attempt receipt-based recovery before reporting failure.
                 */
                try {
                    order = findOrderByReceipt(
                            reservation.receipt,
                            reservation.amountInPaise);
                } catch (RuntimeException recoveryException) {
                    createException.addSuppressed(recoveryException);
                }

                if (order == null) {
                    throw new ResponseStatusException(
                            HttpStatus.BAD_GATEWAY,
                            "Razorpay order creation could not be confirmed. "
                                    + "The local reservation was retained; "
                                    + "retry to reconcile the order.",
                            createException);
                }
            }
        }

        String orderId = validateGatewayOrder(
                order,
                reservation.receipt,
                reservation.amountInPaise);

        try {
            persistOrderId(reservation.registrationId, orderId);

        } catch (RuntimeException firstPersistenceFailure) {

            boolean recovered = false;

            try {
                persistOrderId(reservation.registrationId, orderId);
                recovered = true;
            } catch (RuntimeException retryFailure) {
                firstPersistenceFailure.addSuppressed(retryFailure);
            }

            if (!recovered) {
                try {
                    Order recoveredOrder = findOrderByReceipt(
                            reservation.receipt,
                            reservation.amountInPaise);

                    if (recoveredOrder != null) {
                        String recoveredOrderId = validateGatewayOrder(
                                recoveredOrder,
                                reservation.receipt,
                                reservation.amountInPaise);

                        persistOrderId(
                                reservation.registrationId,
                                recoveredOrderId);

                        orderId = recoveredOrderId;
                        recovered = true;
                    }

                } catch (RuntimeException recoveryFailure) {
                    firstPersistenceFailure.addSuppressed(recoveryFailure);
                }
            }

            if (!recovered) {
                throw new ResponseStatusException(
                        HttpStatus.SERVICE_UNAVAILABLE,
                        "The Razorpay order may exist, but its ID could not "
                                + "be saved locally. The reservation was retained. "
                                + "Retry after database connectivity is restored.",
                        firstPersistenceFailure);
            }
        }

        if (reservation.expired) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "The payment reservation has expired. "
                            + "The order was reconciled, but registration "
                            + "has not been confirmed.");
        }

        return toResponse(reservation, orderId);
    }

    private void validateInput(Long userId, Long eventId) {

        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "A valid authenticated user is required");
        }

        if (eventId == null || eventId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "A valid event ID is required");
        }
    }

    /**
     * Runs within TransactionTemplate. The transaction commits before
     * the caller communicates with Razorpay.
     */
    private Reservation prepareReservation(Long userId, Long eventId) {

        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Student profile not found"));

        Event event = eventRepository.findByIdForUpdate(eventId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Event not found"));

        if (event.isDeleted()) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Event not found");
        }

        if (event.getStatus() != EventStatus.PUBLISHED) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Registration is available only for published events");
        }

        if (event.getPaymentType() != PaymentType.PAID) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "This is not a paid event. Use free-event registration.");
        }

        LocalDateTime now = LocalDateTime.now();

        EventRegistration existing = registrationRepository
                .findByEventIdAndStudentId(eventId, student.getId())
                .orElse(null);

        if (existing != null) {

            if (existing.getStatus()
                    != EventRegistrationStatus.PAYMENT_PENDING) {

                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "A registration record already exists for this event. "
                                + "A new payment attempt is not supported "
                                + "by the current payment schema.");
            }

            Payment existingPayment = paymentRepository
                    .findByRegistrationId(existing.getId())
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "The existing reservation has no payment record"));

            /*
             * Do not reuse FAILED, PAID, or refund-state payments to create
             * another order. Reconciliation must happen first.
             */
            if (existingPayment.getStatus() != PaymentStatus.PENDING) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "The existing payment is not eligible for order creation. "
                                + "Payment reconciliation is required.");
            }

            LocalDateTime expiry = existing.getPaymentExpiresAt();
            boolean expired = expiry == null || !now.isBefore(expiry);

            return new Reservation(
                    existing.getId(),
                    event.getId(),
                    student.getId(),
                    existingPayment.getAmount(),
                    toPaise(existingPayment.getAmount()),
                    receiptFor(eventId, student.getId(), existing.getId()),
                    existingPayment.getRazorpayOrderId(),
                    expired);
        }

        LocalDateTime deadline = event.getRegistrationDeadline();

        if (deadline != null && !now.isBefore(deadline)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "The registration deadline has passed");
        }

        if (event.getCapacityType() == CapacityType.LIMITED) {

            if (event.getCapacity() == null || event.getCapacity() <= 0) {
                throw new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "The event has an invalid capacity configuration");
            }

            long registeredCount =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.REGISTERED);

            long pendingCount =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.PAYMENT_PENDING);

            if (registeredCount + pendingCount >= event.getCapacity()) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Event registration capacity is full");
            }
        }

        BigDecimal amount = event.getRegistrationFee();

        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "The paid event has an invalid registration fee");
        }

        long amountInPaise = toPaise(amount);

        EventRegistration registration = new EventRegistration();
        registration.setEvent(event);
        registration.setStudent(student);
        registration.setStatus(EventRegistrationStatus.PAYMENT_PENDING);
        registration.setRegisteredAt(now);
        registration.setPaymentExpiresAt(now.plusMinutes(15));
        registration.setConfirmedAt(null);

        EventRegistration savedRegistration =
                registrationRepository.saveAndFlush(registration);

        Payment payment = new Payment();
        payment.setRegistration(savedRegistration);
        payment.setAmount(amount);
        payment.setStatus(PaymentStatus.PENDING);
        payment.setCreatedAt(now);

        paymentRepository.saveAndFlush(payment);

        return new Reservation(
                savedRegistration.getId(),
                event.getId(),
                student.getId(),
                amount,
                amountInPaise,
                receiptFor(eventId, student.getId(), savedRegistration.getId()),
                null,
                false);
    }

    private Order findOrderByReceipt(
            String receipt,
            long expectedAmountPaise) {

        try {
            JSONObject params = new JSONObject();
            params.put("receipt", receipt);
            params.put("count", 100);

            List<Order> orders = razorpayClient.orders.fetchAll(params);

            Order match = null;

            for (Order candidate : orders) {
                JSONObject json = candidate.toJson();

                if (!receipt.equals(json.optString("receipt", ""))) {
                    continue;
                }

                validateGatewayOrder(
                        candidate,
                        receipt,
                        expectedAmountPaise);

                if (match != null) {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "Multiple Razorpay orders were found for the same receipt");
                }

                match = candidate;
            }

            return match;

        } catch (ResponseStatusException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Unable to reconcile the Razorpay order by receipt",
                    exception);
        }
    }

    private String validateGatewayOrder(
            Order order,
            String expectedReceipt,
            long expectedAmountPaise) {

        JSONObject json = order.toJson();
        String orderId = json.optString("id", "");

        if (orderId.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Razorpay returned an order without an ID");
        }

        if (!expectedReceipt.equals(json.optString("receipt", ""))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "The Razorpay order receipt does not match the reservation");
        }

        if (!"INR".equalsIgnoreCase(json.optString("currency", ""))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "The Razorpay order currency is invalid");
        }

        if (json.optLong("amount", -1) != expectedAmountPaise) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "The Razorpay order amount does not match the reservation");
        }

        return orderId;
    }

    private void persistOrderId(Long registrationId, String orderId) {

        transactionTemplate.executeWithoutResult(transactionStatus -> {

            registrationRepository.findByIdForUpdate(registrationId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND,
                            "Registration not found while saving Razorpay order"));

            Payment payment = paymentRepository
                    .findByRegistrationIdForUpdate(registrationId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND,
                            "Payment not found while saving Razorpay order"));

            String currentOrderId = payment.getRazorpayOrderId();

            if (currentOrderId != null && !currentOrderId.isBlank()) {

                if (!currentOrderId.equals(orderId)) {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "A different Razorpay order is already associated "
                                    + "with this registration");
                }

                return;
            }

            payment.setRazorpayOrderId(orderId);
            payment.setUpdatedAt(LocalDateTime.now());

            paymentRepository.saveAndFlush(payment);
        });
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
                    "The payment amount must have at most two decimal places",
                    exception);
        }
    }

    private String receiptFor(
            Long eventId,
            Long studentId,
            Long registrationId) {

        return "CAMPUS_"
                + eventId
                + "_"
                + studentId
                + "_"
                + registrationId;
    }

    private RazorpayOrderResponse toResponse(
            Reservation reservation,
            String orderId) {

        return new RazorpayOrderResponse(
                reservation.registrationId,
                reservation.eventId,
                reservation.amount,
                "INR",
                orderId,
                razorpayKeyId);
    }

    private static final class Reservation {

        private final Long registrationId;
        private final Long eventId;
        private final Long studentId;
        private final BigDecimal amount;
        private final long amountInPaise;
        private final String receipt;
        private final String orderId;
        private final boolean expired;

        private Reservation(
                Long registrationId,
                Long eventId,
                Long studentId,
                BigDecimal amount,
                long amountInPaise,
                String receipt,
                String orderId,
                boolean expired) {

            this.registrationId = registrationId;
            this.eventId = eventId;
            this.studentId = studentId;
            this.amount = amount;
            this.amountInPaise = amountInPaise;
            this.receipt = receipt;
            this.orderId = orderId;
            this.expired = expired;
        }
    }
}
