
package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.EventRegistrationResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.campussync.campussync_backend.repository.StudentRepository;

@Service
public class EventRegistrationService {

    private final EventRepository eventRepository;
    private final StudentRepository studentRepository;
    private final EventRegistrationRepository registrationRepository;
    private final PaymentRepository paymentRepository;
    private final NotificationService notificationService;

    public EventRegistrationService(
            EventRepository eventRepository,
            StudentRepository studentRepository,
            EventRegistrationRepository registrationRepository,
            PaymentRepository paymentRepository,
            NotificationService notificationService) {

        this.eventRepository = eventRepository;
        this.studentRepository = studentRepository;
        this.registrationRepository = registrationRepository;
        this.paymentRepository = paymentRepository;
        this.notificationService = notificationService;
    }

    // ============================================================
    // STUDENT REGISTER
    // ============================================================

    @Transactional
    public EventRegistrationResponse register(
            Long userId,
            Long eventId) {

        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException("Student account not found"));

        // Lock the event so concurrent registrations cannot
        // independently pass the last-seat capacity check.
        Event event = eventRepository.findByIdForUpdate(eventId)
                .orElseThrow(() ->
                        new RuntimeException("Event not found"));

        if (event.getStatus() != EventStatus.PUBLISHED) {
            throw new RuntimeException(
                    "Event is not open for registration");
        }

        LocalDateTime now = LocalDateTime.now();

        if (event.getRegistrationDeadline() == null
                || !now.isBefore(event.getRegistrationDeadline())) {
            throw new RuntimeException(
                    "Registration deadline has ended");
        }

        // Find any previous registration for this event/student.
        EventRegistration existing = registrationRepository
                .findByEventIdAndStudentId(eventId, student.getId())
                .orElse(null);

        if (existing != null) {

            // Lock and re-read the existing registration before
            // making decisions based on its current status.
            existing = registrationRepository
                    .findByIdForUpdate(existing.getId())
                    .orElseThrow(() ->
                            new RuntimeException(
                                    "Registration not found"));

            if (existing.getStatus()
                    == EventRegistrationStatus.REGISTERED) {
                throw new RuntimeException(
                        "Student is already registered for this event");
            }

            if (existing.getStatus()
                            == EventRegistrationStatus.REFUND_PENDING
                    || existing.getStatus()
                            == EventRegistrationStatus.REFUNDED) {
                throw new RuntimeException(
                        "Student cannot register again for this event");
            }

            if (existing.getStatus()
                    == EventRegistrationStatus.PAYMENT_PENDING) {

                LocalDateTime expiry = existing.getPaymentExpiresAt();

                if (expiry != null && now.isBefore(expiry)) {
                    throw new RuntimeException(
                            "Student already has a pending payment");
                }

                // Expired reservation: lock its payment after its
                // registration, following the common lock order.
                Payment oldPayment = paymentRepository
                        .findByRegistrationIdForUpdate(existing.getId())
                        .orElse(null);

                if (oldPayment != null) {

                    // Never recycle a registration whose payment
                    // is already recorded as successful.
                    if (oldPayment.getStatus() == PaymentStatus.PAID) {
                        throw new RuntimeException(
                                "Payment is already marked as paid. "
                                + "Please contact the event organizer.");
                    }

                    if (oldPayment.getStatus() == PaymentStatus.PENDING) {
                        oldPayment.setStatus(PaymentStatus.FAILED);
                        oldPayment.setUpdatedAt(now);
                        paymentRepository.save(oldPayment);
                    }
                }

                existing.setStatus(EventRegistrationStatus.CANCELLED);
                existing.setPaymentExpiresAt(null);
                registrationRepository.save(existing);
            }
        }

        // Both REGISTERED and PAYMENT_PENDING occupy a seat.
        if (event.getCapacityType() == CapacityType.LIMITED) {

            long occupiedSeats = countOccupiedSeats(eventId);

            // If the existing reservation was expired above, it is
            // now CANCELLED and no longer included in this count.
            if (occupiedSeats >= event.getCapacity()) {
                throw new RuntimeException("Event is fully booked");
            }
        }

        EventRegistration registration;

        if (existing != null) {
            // IMPORTANT: Reuse the existing row. The database has a
            // unique constraint on (event_id, student_id).
            registration = existing;
        } else {
            registration = new EventRegistration();
            registration.setEvent(event);
            registration.setStudent(student);
        }

        registration.setRegisteredAt(now);
        registration.setConfirmedAt(null);

        if (event.getPaymentType() == PaymentType.PAID) {
            registration.setStatus(
                    EventRegistrationStatus.PAYMENT_PENDING);
            registration.setPaymentExpiresAt(now.plusMinutes(15));
        } else {
            registration.setStatus(
                    EventRegistrationStatus.REGISTERED);
            registration.setPaymentExpiresAt(null);
            registration.setConfirmedAt(now);
        }

        try {
            registration = registrationRepository.save(registration);
        } catch (DataIntegrityViolationException e) {
            throw new RuntimeException(
                    "Student is already registered for this event", e);
        }

        if (registration.getStatus()
                == EventRegistrationStatus.REGISTERED) {

            notificationService.createNotification(
                    userId,
                    "Registration Confirmed",
                    "You have successfully registered for the event \""
                            + event.getTitle() + "\".",
                    NotificationType.REGISTRATION_CONFIRMED,
                    event
            );
        }

        return toResponse(registration);
    }

    // ============================================================
    // COUNT OCCUPIED SEATS
    // ============================================================

    private long countOccupiedSeats(Long eventId) {

        long registered = registrationRepository
                .countByEventIdAndStatus(
                        eventId,
                        EventRegistrationStatus.REGISTERED);

        long paymentPending = registrationRepository
                .countByEventIdAndStatus(
                        eventId,
                        EventRegistrationStatus.PAYMENT_PENDING);

        return registered + paymentPending;
    }

    // ============================================================
    // ORGANIZER: GET REGISTERED STUDENTS
    // ============================================================

    @Transactional(readOnly = true)
    public List<EventRegistrationResponse> getRegisteredStudents(
            Long userId,
            Long eventId) {

        Event event = eventRepository.findByIdAndDeletedFalse(eventId)
                .orElseThrow(() ->
                        new RuntimeException("Event not found"));

        if (!event.getOrganizer().getUser().getId().equals(userId)) {
            throw new RuntimeException(
                    "You are not allowed to view this event");
        }

        return registrationRepository
                .findByEventIdAndStatusOrderByRegisteredAtAsc(
                        eventId,
                        EventRegistrationStatus.REGISTERED)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // EXPIRE PAYMENT RESERVATION
    // ============================================================

    @Transactional
    public void expirePaymentReservation(Long registrationId) {

        // Always lock registration before its associated payment.
        EventRegistration registration = registrationRepository
                .findByIdForUpdate(registrationId)
                .orElseThrow(() ->
                        new RuntimeException("Registration not found"));

        if (registration.getStatus()
                != EventRegistrationStatus.PAYMENT_PENDING) {
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime expiry = registration.getPaymentExpiresAt();

        if (expiry != null && now.isBefore(expiry)) {
            return;
        }

        Payment payment = paymentRepository
                .findByRegistrationIdForUpdate(registrationId)
                .orElse(null);

        if (payment != null) {

            // A successful payment must not be silently cancelled.
            if (payment.getStatus() == PaymentStatus.PAID) {
                throw new RuntimeException(
                        "Registration has a paid payment and requires reconciliation");
            }

            if (payment.getStatus() == PaymentStatus.PENDING) {
                payment.setStatus(PaymentStatus.FAILED);
                payment.setUpdatedAt(now);
                paymentRepository.save(payment);
            }
        }

        registration.setStatus(EventRegistrationStatus.CANCELLED);
        registration.setPaymentExpiresAt(null);

        registrationRepository.save(registration);
    }

    // ============================================================
    // MAPPING
    // ============================================================

    private EventRegistrationResponse toResponse(
            EventRegistration registration) {

        Student student = registration.getStudent();
        User user = student.getUser();

        return new EventRegistrationResponse(
                registration.getId(),
                registration.getEvent().getId(),
                student.getId(),
                user.getName(),
                user.getEmail(),
                user.getPhoneNumber(),
                student.getRegisterNumber(),
                student.getDepartment().getId(),
                student.getDepartment().getName(),
                student.getBranch().getId(),
                student.getBranch().getName(),
                student.getProgramme(),
                student.getAdmissionYear(),
                student.getSemester(),
                student.getGraduationYear(),
                student.isInternal(),
                registration.getStatus(),
                registration.getRegisteredAt()
        );
    }
}
