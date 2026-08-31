package com.campussync.campussync_backend.service;

import java.util.List;
import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.PaymentResponse;
import com.campussync.campussync_backend.dto.SubmitPaymentRequest;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.campussync.campussync_backend.repository.StudentRepository;

@Service
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final EventRegistrationRepository registrationRepository;
    private final StudentRepository studentRepository;

    public PaymentService(
            PaymentRepository paymentRepository,
            EventRegistrationRepository registrationRepository,
            StudentRepository studentRepository) {

        this.paymentRepository = paymentRepository;
        this.registrationRepository = registrationRepository;
        this.studentRepository = studentRepository;
    }

    // ============================================================
    // STUDENT SUBMITS PAYMENT REFERENCE
    // ============================================================

    @Transactional
    public PaymentResponse submitPayment(
            Long userId,
            Long registrationId,
            SubmitPaymentRequest request) {

        Student student =
                studentRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Student account not found"));

        EventRegistration registration =
                registrationRepository.findById(
                        registrationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Registration not found"));

        if (!registration.getStudent()
                .getId()
                .equals(student.getId())) {

            throw new RuntimeException(
                    "You are not allowed to modify this registration");
        }

        if (registration.getStatus() !=
                EventRegistrationStatus.PAYMENT_PENDING) {

            throw new RuntimeException(
                    "This registration is not awaiting payment");
        }

        LocalDateTime expiry =
                registration.getPaymentExpiresAt();

        if (expiry == null ||
                !LocalDateTime.now().isBefore(expiry)) {

            registration.setStatus(
                    EventRegistrationStatus.CANCELLED);

            registration.setPaymentExpiresAt(null);

            registrationRepository.save(registration);

            throw new RuntimeException(
                    "Payment reservation has expired");
        }

        Payment payment =
                paymentRepository
                        .findByRegistrationId(
                                registrationId)
                        .orElse(null);

        if (payment == null) {

            payment = new Payment();

            payment.setRegistration(
                    registration);

            payment.setAmount(
                    registration.getEvent()
                            .getRegistrationFee());

            payment.setStatus(
                    PaymentStatus.PENDING);

            payment.setCreatedAt(
                    LocalDateTime.now());
        }

        if (payment.getStatus() ==
                PaymentStatus.PAID) {

            throw new RuntimeException(
                    "Payment has already been completed");
        }

        payment.setPaymentReference(
                request.paymentReference());

        payment.setStatus(
                PaymentStatus.PENDING);

        payment.setUpdatedAt(
                LocalDateTime.now());

        payment =
                paymentRepository.save(payment);

        return toResponse(payment);
    }

    // ============================================================
    // PAYMENT LOOKUP
    // ============================================================

    @Transactional(readOnly = true)
    public PaymentResponse getPayment(
            Long userId,
            Long registrationId) {

        Student student =
                studentRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Student account not found"));

        Payment payment =
                paymentRepository
                        .findByRegistrationId(
                                registrationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Payment not found"));

        if (!payment.getRegistration()
                .getStudent()
                .getId()
                .equals(student.getId())) {

            throw new RuntimeException(
                    "You are not allowed to view this payment");
        }

        return toResponse(payment);
    }

    // ============================================================
    // MAPPING
    // ============================================================

    private PaymentResponse toResponse(
            Payment payment) {

        EventRegistration registration =
                payment.getRegistration();

        Student student =
                registration.getStudent();

        User user =
                student.getUser();

        return new PaymentResponse(
                payment.getId(),
                registration.getId(),
                registration.getEvent().getId(),
                student.getId(),
                user.getName(),
                user.getEmail(),
                payment.getAmount(),
                payment.getStatus(),
                payment.getPaymentReference(),
                payment.getCreatedAt(),
                payment.getPaidAt()
        );
    }
    // ============================================================
// ORGANIZER: VIEW PAYMENT HISTORY
// ============================================================

@Transactional(readOnly = true)
public List<PaymentResponse> getOrganizerPaymentHistory(
        Long userId) {

    return paymentRepository
            .findByRegistrationEventOrganizerUserIdOrderByCreatedAtDesc(
                    userId)
            .stream()
            .map(this::toResponse)
            .toList();
}


// ============================================================
// ORGANIZER: APPROVE PAYMENT
// ============================================================

@Transactional
public PaymentResponse approvePayment(
        Long userId,
        Long paymentId) {

    Payment payment =
            paymentRepository.findById(paymentId)
                    .orElseThrow(() ->
                            new RuntimeException(
                                    "Payment not found"));

    EventRegistration registration =
            payment.getRegistration();

    if (!registration.getEvent()
            .getOrganizer()
            .getUser()
            .getId()
            .equals(userId)) {

        throw new RuntimeException(
                "You are not allowed to verify this payment");
    }

    if (payment.getStatus() !=
            PaymentStatus.PENDING) {

        throw new RuntimeException(
                "Payment is not pending verification");
    }

    if (registration.getStatus() !=
            EventRegistrationStatus.PAYMENT_PENDING) {

        throw new RuntimeException(
                "Registration is not awaiting payment");
    }

    LocalDateTime now =
            LocalDateTime.now();

    /*
     * Do not allow an expired payment reservation
     * to become registered.
     */
    if (registration.getPaymentExpiresAt() == null ||
            !now.isBefore(
                    registration.getPaymentExpiresAt())) {

        payment.setStatus(
                PaymentStatus.FAILED);

        payment.setUpdatedAt(now);

        paymentRepository.save(payment);

        registration.setStatus(
                EventRegistrationStatus.CANCELLED);

        registration.setPaymentExpiresAt(null);

        registrationRepository.save(registration);

        throw new RuntimeException(
                "Payment reservation has expired");
    }

    payment.setStatus(
            PaymentStatus.PAID);

    payment.setPaidAt(now);
    payment.setUpdatedAt(now);

    paymentRepository.save(payment);

    registration.setStatus(
            EventRegistrationStatus.REGISTERED);

    registration.setConfirmedAt(now);
    registration.setPaymentExpiresAt(null);

    registrationRepository.save(registration);

    return toResponse(payment);
}


// ============================================================
// ORGANIZER: REJECT PAYMENT
// ============================================================

@Transactional
public PaymentResponse rejectPayment(
        Long userId,
        Long paymentId) {

    Payment payment =
            paymentRepository.findById(paymentId)
                    .orElseThrow(() ->
                            new RuntimeException(
                                    "Payment not found"));

    EventRegistration registration =
            payment.getRegistration();

    if (!registration.getEvent()
            .getOrganizer()
            .getUser()
            .getId()
            .equals(userId)) {

        throw new RuntimeException(
                "You are not allowed to verify this payment");
    }

    if (payment.getStatus() !=
            PaymentStatus.PENDING) {

        throw new RuntimeException(
                "Payment is not pending verification");
    }

    payment.setStatus(
            PaymentStatus.FAILED);

    payment.setUpdatedAt(
            LocalDateTime.now());

    paymentRepository.save(payment);

    /*
     * Release the reserved seat.
     */
    registration.setStatus(
            EventRegistrationStatus.CANCELLED);

    registration.setPaymentExpiresAt(null);

    registrationRepository.save(registration);

    return toResponse(payment);
}
}