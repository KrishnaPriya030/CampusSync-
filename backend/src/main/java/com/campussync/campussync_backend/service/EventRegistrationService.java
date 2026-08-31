package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.EventRegistrationResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.StudentRepository;

@Service
public class EventRegistrationService {

    private final EventRepository eventRepository;
    private final StudentRepository studentRepository;
    private final EventRegistrationRepository registrationRepository;

    public EventRegistrationService(
            EventRepository eventRepository,
            StudentRepository studentRepository,
            EventRegistrationRepository registrationRepository) {

        this.eventRepository = eventRepository;
        this.studentRepository = studentRepository;
        this.registrationRepository = registrationRepository;
    }

    // ============================================================
    // STUDENT REGISTER
    // ============================================================

    @Transactional
    public EventRegistrationResponse register(
            Long userId,
            Long eventId) {

        Student student =
                studentRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Student account not found"));

        /*
         * IMPORTANT:
         *
         * The event is locked at database level.
         *
         * If two students try to take the last seat
         * simultaneously, only one transaction can perform
         * the capacity check at a time.
         */
        Event event =
                eventRepository.findByIdForUpdate(eventId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Event not found"));

        if (event.getStatus() != EventStatus.PUBLISHED) {
            throw new RuntimeException(
                    "Event is not open for registration");
        }

        LocalDateTime now = LocalDateTime.now();

        /*
         * Registration deadline is enforced by backend.
         */
        if (!now.isBefore(
                event.getRegistrationDeadline())) {

            throw new RuntimeException(
                    "Registration deadline has ended");
        }

        /*
         * Check whether the student already has an active
         * registration/reservation.
         */
        EventRegistration existing =
                registrationRepository
                        .findByEventIdAndStudentId(
                                eventId,
                                student.getId())
                        .orElse(null);

        if (existing != null) {

            /*
             * If an old payment reservation expired,
             * release it before allowing a new reservation.
             */
            if (existing.getStatus() ==
                    EventRegistrationStatus.PAYMENT_PENDING) {

                LocalDateTime expiry =
                        existing.getPaymentExpiresAt();

                if (expiry != null &&
                        !now.isBefore(expiry)) {

                    existing.setStatus(
                            EventRegistrationStatus.CANCELLED);

                    existing.setPaymentExpiresAt(null);

                    registrationRepository.save(existing);

                } else {

                    throw new RuntimeException(
                            "Student already has a pending payment");
                }

            } else if (
                    existing.getStatus() ==
                            EventRegistrationStatus.REGISTERED) {

                throw new RuntimeException(
                        "Student is already registered for this event");

            } else if (
                    existing.getStatus() ==
                            EventRegistrationStatus.REFUND_PENDING ||
                    existing.getStatus() ==
                            EventRegistrationStatus.REFUNDED) {

                throw new RuntimeException(
                        "Student cannot register again for this event");
            }
        }

        /*
         * Count both confirmed registrations and active
         * payment reservations.
         *
         * This is important because a payment-pending student
         * temporarily owns a seat.
         */
        if (event.getCapacityType() ==
                CapacityType.LIMITED) {

            long occupiedSeats =
                    countOccupiedSeats(eventId);

            if (occupiedSeats >=
                    event.getCapacity()) {

                throw new RuntimeException(
                        "Event is fully booked");
            }
        }

        EventRegistration registration;

        if (event.getPaymentType() ==
                PaymentType.PAID) {

            /*
             * Paid event:
             *
             * Reserve the seat temporarily.
             *
             * Payment module will later create the actual
             * Payment record and verify the payment.
             */
            registration =
                    new EventRegistration();

            registration.setEvent(event);
            registration.setStudent(student);

            registration.setStatus(
                    EventRegistrationStatus.PAYMENT_PENDING);

            registration.setRegisteredAt(now);

            /*
             * Temporary reservation period.
             *
             * We will make this configurable later.
             */
            registration.setPaymentExpiresAt(
                    now.plusMinutes(15));

            registration.setConfirmedAt(null);

        } else {

            /*
             * Free event:
             *
             * Registration is immediately confirmed.
             */
            registration =
                    new EventRegistration();

            registration.setEvent(event);
            registration.setStudent(student);

            registration.setStatus(
                    EventRegistrationStatus.REGISTERED);

            registration.setRegisteredAt(now);
            registration.setPaymentExpiresAt(null);
            registration.setConfirmedAt(now);
        }

        try {

            registration =
                    registrationRepository.save(
                            registration);

        } catch (DataIntegrityViolationException e) {

            /*
             * Final database-level duplicate protection.
             */
            throw new RuntimeException(
                    "Student is already registered for this event");
        }

        return toResponse(registration);
    }

    // ============================================================
    // COUNT OCCUPIED SEATS
    // ============================================================

    private long countOccupiedSeats(
            Long eventId) {

        long registered =
                registrationRepository
                        .countByEventIdAndStatus(
                                eventId,
                                EventRegistrationStatus.REGISTERED);

        long paymentPending =
                registrationRepository
                        .countByEventIdAndStatus(
                                eventId,
                                EventRegistrationStatus.PAYMENT_PENDING);

        /*
         * Both states occupy a seat.
         */
        return registered + paymentPending;
    }

    // ============================================================
    // ORGANIZER: GET REGISTERED STUDENTS
    // ============================================================

    @Transactional(readOnly = true)
    public List<EventRegistrationResponse>
    getRegisteredStudents(
            Long userId,
            Long eventId) {

        Event event =
                eventRepository
                        .findByIdAndDeletedFalse(eventId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Event not found"));

        /*
         * Organizer ownership check.
         */
        if (!event.getOrganizer()
                .getUser()
                .getId()
                .equals(userId)) {

            throw new RuntimeException(
                    "You are not allowed to view this event");
        }

        /*
         * Organizer sees confirmed registrations.
         *
         * PAYMENT_PENDING students are not included as
         * confirmed registrations.
         */
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
    public void expirePaymentReservation(
            Long registrationId) {

        EventRegistration registration =
                registrationRepository
                        .findById(registrationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Registration not found"));

        if (registration.getStatus() !=
                EventRegistrationStatus.PAYMENT_PENDING) {

            return;
        }

        LocalDateTime expiry =
                registration.getPaymentExpiresAt();

        if (expiry == null ||
                LocalDateTime.now().isBefore(expiry)) {

            return;
        }

        registration.setStatus(
                EventRegistrationStatus.CANCELLED);

        registration.setPaymentExpiresAt(null);

        registrationRepository.save(registration);
    }

    // ============================================================
    // MAPPING
    // ============================================================

    private EventRegistrationResponse toResponse(
            EventRegistration registration) {

        Student student =
                registration.getStudent();

        User user =
                student.getUser();

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