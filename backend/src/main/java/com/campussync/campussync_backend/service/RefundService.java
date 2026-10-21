
package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

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
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.campussync.campussync_backend.repository.RefundRepository;
import com.campussync.campussync_backend.repository.StudentRepository;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;

@Service
public class RefundService {

    private static final Logger log =
            LoggerFactory.getLogger(RefundService.class);

    private final RefundRepository refundRepository;
    private final PaymentRepository paymentRepository;
    private final StudentRepository studentRepository;
    private final EventRegistrationRepository registrationRepository;
    private final RazorpayClient razorpayClient;
    private final NotificationService notificationService;

    public RefundService(
            RefundRepository refundRepository,
            PaymentRepository paymentRepository,
            StudentRepository studentRepository,
            EventRegistrationRepository registrationRepository,
            RazorpayClient razorpayClient,
            NotificationService notificationService) {

        this.refundRepository = refundRepository;
        this.paymentRepository = paymentRepository;
        this.studentRepository = studentRepository;
        this.registrationRepository = registrationRepository;
        this.razorpayClient = razorpayClient;
        this.notificationService = notificationService;
    }

    // ---------------------------------------------------------
    // Lock registration first, then payment.
    // ---------------------------------------------------------

    private Payment lockPaymentAndRegistration(Long paymentId) {

        Payment initial = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Payment not found"));

        if (initial.getRegistration() == null
                || initial.getRegistration().getId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Payment has no associated registration");
        }

        Long registrationId = initial.getRegistration().getId();

        registrationRepository.findByIdForUpdate(registrationId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Registration not found"));

        Payment payment = paymentRepository.findByIdForUpdate(paymentId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Payment not found"));

        if (payment.getRegistration() == null
                || !registrationId.equals(payment.getRegistration().getId())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Payment registration changed unexpectedly");
        }

        return payment;
    }

    private Refund lockRefundPaymentAndRegistration(Long refundId) {

        Refund initialRefund = refundRepository.findById(refundId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Refund not found"));

        if (initialRefund.getPayment() == null
                || initialRefund.getPayment().getId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Refund has no associated payment");
        }

        Long paymentId = initialRefund.getPayment().getId();

        lockPaymentAndRegistration(paymentId);

        return refundRepository.findById(refundId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Refund not found"));
    }

    private void requireOrganizerOwnership(
            Long userId,
            EventRegistration registration) {

        if (userId == null
                || registration.getEvent() == null
                || registration.getEvent().getOrganizer() == null
                || registration.getEvent().getOrganizer().getUser() == null
                || registration.getEvent().getOrganizer().getUser().getId() == null
                || !registration.getEvent().getOrganizer()
                        .getUser().getId().equals(userId)) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "You are not allowed to process this refund");
        }
    }

    // ---------------------------------------------------------
    // STUDENT: REQUEST REFUND
    // ---------------------------------------------------------

    @Transactional
    public RefundResponse requestRefund(
            Long userId,
            Long paymentId,
            RefundRequest request) {

        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Authentication is required");
        }

        if (paymentId == null || paymentId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "A valid payment ID is required");
        }

        if (request == null
                || request.reason() == null
                || request.reason().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "A refund reason is required");
        }

        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Student account not found"));

        Payment payment = lockPaymentAndRegistration(paymentId);
        EventRegistration registration = payment.getRegistration();

        if (registration.getStudent() == null
                || !registration.getStudent().getId().equals(student.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "You are not allowed to request this refund");
        }

        if (payment.getStatus() != PaymentStatus.PAID) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Only captured payments can be refunded");
        }

        if (payment.getRazorpayPaymentId() == null
                || payment.getRazorpayPaymentId().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "The Razorpay payment ID is missing");
        }

        if (payment.getAmount() == null
                || payment.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "The payment amount is invalid");
        }

        if (registration.getEvent() == null) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "The registration has no associated event");
        }

        String policy = registration.getEvent().getRefundPolicy();

        if (policy == null || policy.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "This event does not offer a refund policy");
        }

        // findByPaymentId returns List<Refund>, not Optional<Refund>.
        if (!refundRepository.findByPaymentId(paymentId).isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "A refund request already exists for this payment");
        }

        LocalDateTime now = LocalDateTime.now();

        Refund refund = new Refund();
        refund.setPayment(payment);
        refund.setAmount(payment.getAmount());
        refund.setReason(request.reason().trim());
        refund.setStatus(RefundStatus.PENDING);
        refund.setRequestedAt(now);

        Refund savedRefund = refundRepository.save(refund);

        payment.setStatus(PaymentStatus.REFUND_PENDING);
        payment.setUpdatedAt(now);
        paymentRepository.save(payment);

        registration.setStatus(EventRegistrationStatus.REFUND_PENDING);

        return toResponse(savedRefund);
    }

    // ---------------------------------------------------------
    // STUDENT: REFUND HISTORY
    // ---------------------------------------------------------

    @Transactional(readOnly = true)
    public List<RefundResponse> getStudentRefundHistory(Long userId) {

        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Authentication is required");
        }

        return refundRepository
                .findByPaymentRegistrationStudentUserIdOrderByRequestedAtDesc(
                        userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ---------------------------------------------------------
    // ORGANIZER: REFUND HISTORY
    // ---------------------------------------------------------

    @Transactional(readOnly = true)
    public List<RefundResponse> getOrganizerRefundHistory(Long userId) {

        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Authentication is required");
        }

        return refundRepository
                .findByPaymentRegistrationEventOrganizerUserIdOrderByRequestedAtDesc(
                        userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ---------------------------------------------------------
    // ORGANIZER: APPROVE AND PROCESS REFUND
    // ---------------------------------------------------------

    @Transactional
    public RefundResponse approveRefund(
            Long userId,
            Long refundId,
            String processingNote) {

        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Authentication is required");
        }

        if (refundId == null || refundId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "A valid refund ID is required");
        }

        Refund refund = lockRefundPaymentAndRegistration(refundId);
        Payment payment = refund.getPayment();
        EventRegistration registration = payment.getRegistration();

        requireOrganizerOwnership(userId, registration);

        if (refund.getStatus() != RefundStatus.PENDING) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Refund is not pending");
        }

        if (payment.getStatus() != PaymentStatus.REFUND_PENDING) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Payment is not awaiting a refund");
        }

        String razorpayPaymentId = payment.getRazorpayPaymentId();

        if (razorpayPaymentId == null || razorpayPaymentId.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Razorpay payment ID is missing");
        }

        BigDecimal refundAmount = refund.getAmount();

        if (refundAmount == null
                || refundAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Refund amount is invalid");
        }

        final long amountInPaise;

        try {
            amountInPaise = refundAmount
                    .movePointRight(2)
                    .longValueExact();
        } catch (ArithmeticException exception) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Refund amount must have at most two decimal places",
                    exception);
        }

        try {
            JSONObject refundRequest = new JSONObject();
            refundRequest.put("amount", amountInPaise);

            razorpayClient.payments.refund(
                    razorpayPaymentId, refundRequest);

        } catch (RazorpayException exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Razorpay could not process the refund",
                    exception);
        }

        LocalDateTime now = LocalDateTime.now();

        refund.setStatus(RefundStatus.COMPLETED);
        refund.setProcessingNote(processingNote);
        refund.setProcessedAt(now);
        refundRepository.save(refund);

        payment.setStatus(PaymentStatus.REFUNDED);
        payment.setUpdatedAt(now);
        paymentRepository.save(payment);

        registration.setStatus(EventRegistrationStatus.REFUNDED);

        try {
            notificationService.createNotification(
                    registration.getStudent().getUser().getId(),
                    "Refund Processed",
                    "Your refund of ₹"
                            + refund.getAmount()
                            + " for event \""
                            + registration.getEvent().getTitle()
                            + "\" has been processed successfully.",
                    NotificationType.REFUND_PROCESSED,
                    registration.getEvent());
        } catch (RuntimeException exception) {
            log.error(
                    "Refund {} was accepted, but its notification failed",
                    refundId,
                    exception);
        }

        return toResponse(refund);
    }

    // ---------------------------------------------------------
    // ORGANIZER: REJECT REFUND
    // ---------------------------------------------------------

    @Transactional
    public RefundResponse rejectRefund(
            Long userId,
            Long refundId,
            String processingNote) {

        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Authentication is required");
        }

        if (refundId == null || refundId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "A valid refund ID is required");
        }

        Refund refund = lockRefundPaymentAndRegistration(refundId);
        Payment payment = refund.getPayment();
        EventRegistration registration = payment.getRegistration();

        requireOrganizerOwnership(userId, registration);

        if (refund.getStatus() != RefundStatus.PENDING) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Refund is not pending");
        }

        if (payment.getStatus() != PaymentStatus.REFUND_PENDING) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Payment is not awaiting a refund");
        }

        LocalDateTime now = LocalDateTime.now();

        refund.setStatus(RefundStatus.REJECTED);
        refund.setProcessingNote(processingNote);
        refund.setProcessedAt(now);
        refundRepository.save(refund);

        payment.setStatus(PaymentStatus.PAID);
        payment.setUpdatedAt(now);
        paymentRepository.save(payment);

        registration.setStatus(EventRegistrationStatus.REGISTERED);

        return toResponse(refund);
    }

    // ---------------------------------------------------------
    // MAPPING
    // ---------------------------------------------------------

    private RefundResponse toResponse(Refund refund) {

        Payment payment = refund.getPayment();
        EventRegistration registration = payment.getRegistration();
        Student student = registration.getStudent();

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
                refund.getProcessingNote());
    }
}
