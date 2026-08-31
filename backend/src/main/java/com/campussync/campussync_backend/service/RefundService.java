package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.RefundRequest;
import com.campussync.campussync_backend.dto.RefundResponse;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.entity.Refund;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.enums.RefundStatus;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.campussync.campussync_backend.repository.RefundRepository;
import com.campussync.campussync_backend.repository.StudentRepository;

@Service
public class RefundService {

    private final RefundRepository refundRepository;
    private final PaymentRepository paymentRepository;
    private final StudentRepository studentRepository;

    public RefundService(
            RefundRepository refundRepository,
            PaymentRepository paymentRepository,
            StudentRepository studentRepository) {

        this.refundRepository = refundRepository;
        this.paymentRepository = paymentRepository;
        this.studentRepository = studentRepository;
    }

    // ============================================================
    // STUDENT REQUEST REFUND
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
         * The actual policy interpretation will be handled
         * as part of the event's configured policy.
         *
         * For now we require the event to have a policy
         * before allowing a refund request.
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
         * Mark payment as refund pending.
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

        refund.setStatus(
                RefundStatus.APPROVED);

        refund.setProcessingNote(
                processingNote);

        refund.setProcessedAt(
                LocalDateTime.now());

        refundRepository.save(refund);

        /*
         * The actual money transfer is not performed by
         * CampusSync in the manual QR/UTR model.
         *
         * We record the approved refund.
         */
        payment.setStatus(
                PaymentStatus.REFUNDED);

        payment.setUpdatedAt(
                LocalDateTime.now());

        paymentRepository.save(payment);

        registration.setStatus(
                EventRegistrationStatus.REFUNDED);

        return toResponse(refund);
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

        refund.setStatus(
                RefundStatus.REJECTED);

        refund.setProcessingNote(
                processingNote);

        refund.setProcessedAt(
                LocalDateTime.now());

        refundRepository.save(refund);

        /*
         * Payment becomes paid again because the refund
         * request was rejected.
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