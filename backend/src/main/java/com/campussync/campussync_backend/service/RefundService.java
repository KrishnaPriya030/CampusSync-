package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.json.JSONObject;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.RefundRequest;
import com.campussync.campussync_backend.dto.RefundResponse;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.entity.Refund;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.enums.RefundStatus;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.campussync.campussync_backend.repository.RefundRepository;
import com.campussync.campussync_backend.repository.StudentRepository;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;

@Service
public class RefundService {

    private final RefundRepository refundRepository;
    private final PaymentRepository paymentRepository;
    private final StudentRepository studentRepository;
    private final RazorpayClient razorpayClient;
    private final NotificationService notificationService;

    public RefundService(
            RefundRepository refundRepository,
            PaymentRepository paymentRepository,
            StudentRepository studentRepository,
            RazorpayClient razorpayClient,
            NotificationService notificationService) {

        this.refundRepository = refundRepository;
        this.paymentRepository = paymentRepository;
        this.studentRepository = studentRepository;
        this.razorpayClient = razorpayClient;
        this.notificationService = notificationService;
    }

    // ============================================================
    // STUDENT: REQUEST REFUND
    // ============================================================

    @Transactional
    public RefundResponse requestRefund(
            Long userId,
            Long paymentId,
            RefundRequest request) {

        Student student =
                studentRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Student account not found"));

        Payment payment =
                paymentRepository.findById(paymentId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Payment not found"));

        EventRegistration registration =
                payment.getRegistration();

        if (!registration.getStudent()
                .getId()
                .equals(student.getId())) {

            throw new RuntimeException(
                    "You are not allowed to request this refund");
        }

        if (payment.getStatus() !=
                PaymentStatus.PAID) {

            throw new RuntimeException(
                    "Only paid payments can be refunded");
        }

        /*
         * A real Razorpay payment ID is required
         * for processing the refund.
         */
        if (payment.getRazorpayPaymentId() == null ||
                payment.getRazorpayPaymentId().isBlank()) {

            throw new RuntimeException(
                    "Razorpay payment ID not found");
        }

        Refund existing =
                refundRepository
                        .findByPaymentId(paymentId)
                        .orElse(null);

        if (existing != null) {

            throw new RuntimeException(
                    "A refund request already exists");
        }

        /*
         * Check the refund policy stored on the event.
         *
         * The current implementation only checks that
         * a refund policy exists. It does not interpret
         * the policy text automatically.
         */
        String policy =
                registration.getEvent()
                        .getRefundPolicy();

        if (policy == null ||
                policy.trim().isEmpty()) {

            throw new RuntimeException(
                    "This event does not offer a refund policy");
        }

        Refund refund =
                new Refund();

        refund.setPayment(payment);

        refund.setAmount(
                payment.getAmount());

        refund.setReason(
                request.reason());

        refund.setStatus(
                RefundStatus.PENDING);

        refund.setRequestedAt(
                LocalDateTime.now());

        refundRepository.save(refund);

        /*
         * Payment is now waiting for organizer
         * refund processing.
         */
        payment.setStatus(
                PaymentStatus.REFUND_PENDING);

        payment.setUpdatedAt(
                LocalDateTime.now());

        paymentRepository.save(payment);

        registration.setStatus(
                EventRegistrationStatus.REFUND_PENDING);

        return toResponse(refund);
    }

    // ============================================================
    // STUDENT: REFUND HISTORY
    // ============================================================

    @Transactional(readOnly = true)
    public List<RefundResponse> getStudentRefundHistory(
            Long userId) {

        return refundRepository
                .findByPaymentRegistrationStudentUserIdOrderByRequestedAtDesc(
                        userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // ORGANIZER: REFUND HISTORY
    // ============================================================

    @Transactional(readOnly = true)
    public List<RefundResponse> getOrganizerRefundHistory(
            Long userId) {

        return refundRepository
                .findByPaymentRegistrationEventOrganizerUserIdOrderByRequestedAtDesc(
                        userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // ORGANIZER: APPROVE REFUND
    // ============================================================

    @Transactional
    public RefundResponse approveRefund(
            Long userId,
            Long refundId,
            String processingNote) {

        Refund refund =
                refundRepository.findById(refundId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Refund not found"));

        Payment payment =
                refund.getPayment();

        EventRegistration registration =
                payment.getRegistration();

        /*
         * Only the organizer who owns the event
         * can approve the refund.
         */
        if (!registration.getEvent()
                .getOrganizer()
                .getUser()
                .getId()
                .equals(userId)) {

            throw new RuntimeException(
                    "You are not allowed to process this refund");
        }

        if (refund.getStatus() !=
                RefundStatus.PENDING) {

            throw new RuntimeException(
                    "Refund is not pending");
        }

        if (payment.getStatus() !=
                PaymentStatus.REFUND_PENDING) {

            throw new RuntimeException(
                    "Payment is not awaiting refund");
        }

        /*
         * Razorpay payment ID is required to create
         * the actual refund.
         */
        String razorpayPaymentId =
                payment.getRazorpayPaymentId();

        if (razorpayPaymentId == null ||
                razorpayPaymentId.isBlank()) {

            throw new RuntimeException(
                    "Razorpay payment ID not found");
        }

        /*
         * Amount in our database is stored in RUPEES.
         *
         * Razorpay expects the refund amount in PAISE.
         *
         * Example:
         * ₹100.00 -> 10000 paise
         */
        BigDecimal amountInRupees =
                refund.getAmount();

        long amountInPaise =
                amountInRupees
                        .movePointRight(2)
                        .longValueExact();

        try {

            /*
             * Create Razorpay refund request.
             */
            JSONObject refundRequest =
                    new JSONObject();

            refundRequest.put(
                    "amount",
                    amountInPaise);

            /*
             * Create the actual refund in Razorpay.
             */
            com.razorpay.Refund razorpayRefund =
                    razorpayClient
                            .payments
                            .refund(
                                    razorpayPaymentId,
                                    refundRequest);

            /*
             * Razorpay successfully accepted the refund.
             *
             * We now update our local database.
             */
            refund.setStatus(
                    RefundStatus.COMPLETED);

            refund.setProcessingNote(
                    processingNote);

            refund.setProcessedAt(
                    LocalDateTime.now());

            refundRepository.save(refund);

            payment.setStatus(
                    PaymentStatus.REFUNDED);

            payment.setUpdatedAt(
                    LocalDateTime.now());

            paymentRepository.save(payment);

            registration.setStatus(
                    EventRegistrationStatus.REFUNDED);

            /*
             * Notify the student only after the
             * Razorpay refund was successfully accepted.
             */
            notificationService.createNotification(
                    registration.getStudent()
                            .getUser()
                            .getId(),
                    "Refund Processed",
                    "Your refund of ₹"
                            + refund.getAmount()
                            + " for the event \""
                            + registration.getEvent()
                                    .getTitle()
                            + "\" has been processed successfully.",
                    NotificationType.REFUND_PROCESSED,
                    registration.getEvent()
            );

            return toResponse(refund);

        } catch (RazorpayException e) {

            /*
             * Razorpay rejected/failed the refund.
             *
             * Do NOT mark the payment as REFUNDED.
             */
            throw new RuntimeException(
                    "Razorpay refund failed: "
                            + e.getMessage(),
                    e);
        }
    }

    // ============================================================
    // ORGANIZER: REJECT REFUND
    // ============================================================

    @Transactional
    public RefundResponse rejectRefund(
            Long userId,
            Long refundId,
            String processingNote) {

        Refund refund =
                refundRepository.findById(refundId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Refund not found"));

        Payment payment =
                refund.getPayment();

        EventRegistration registration =
                payment.getRegistration();

        if (!registration.getEvent()
                .getOrganizer()
                .getUser()
                .getId()
                .equals(userId)) {

            throw new RuntimeException(
                    "You are not allowed to process this refund");
        }

        if (refund.getStatus() !=
                RefundStatus.PENDING) {

            throw new RuntimeException(
                    "Refund is not pending");
        }

        if (payment.getStatus() !=
                PaymentStatus.REFUND_PENDING) {

            throw new RuntimeException(
                    "Payment is not awaiting refund");
        }

        refund.setStatus(
                RefundStatus.REJECTED);

        refund.setProcessingNote(
                processingNote);

        refund.setProcessedAt(
                LocalDateTime.now());

        refundRepository.save(refund);

        /*
         * Refund was rejected, so the original payment
         * remains successful.
         */
        payment.setStatus(
                PaymentStatus.PAID);

        payment.setUpdatedAt(
                LocalDateTime.now());

        paymentRepository.save(payment);

        registration.setStatus(
                EventRegistrationStatus.REGISTERED);

        return toResponse(refund);
    }

    // ============================================================
    // MAPPING
    // ============================================================

    private RefundResponse toResponse(
            Refund refund) {

        Payment payment =
                refund.getPayment();

        EventRegistration registration =
                payment.getRegistration();

        Student student =
                registration.getStudent();

        return new RefundResponse(
                refund.getId(),
                payment.getId(),
                registration.getId(),
                registration.getEvent().getId(),
                student.getId(),
                student.getUser().getName(),
                student.getUser().getEmail(),
                refund.getAmount(),
                refund.getReason(),
                refund.getStatus(),
                refund.getRequestedAt(),
                refund.getProcessedAt(),
                refund.getProcessingNote()
        );
    }
}