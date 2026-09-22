package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.EventRegistrationResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.StudentRepository;

@Service
public class StudentRegistrationService {

    private final EventRepository eventRepository;
    private final StudentRepository studentRepository;
    private final EventRegistrationRepository registrationRepository;

    public StudentRegistrationService(
            EventRepository eventRepository,
            StudentRepository studentRepository,
            EventRegistrationRepository registrationRepository) {

        this.eventRepository = eventRepository;
        this.studentRepository = studentRepository;
        this.registrationRepository = registrationRepository;
    }

    @Transactional
    public EventRegistrationResponse registerStudent(
            Long userId,
            Long eventId) {

        // ========================================================
        // FIND STUDENT
        // ========================================================

        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Student profile not found"));

        // ========================================================
        // LOCK EVENT ROW
        // ========================================================

        Event event = eventRepository.findByIdForUpdate(eventId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Event not found"));

        // ========================================================
        // EVENT MUST BE PUBLISHED
        // ========================================================

        if (event.isDeleted()) {
            throw new RuntimeException(
                    "Event not found");
        }

        if (event.getStatus() != EventStatus.PUBLISHED) {
            throw new RuntimeException(
                    "Registration is available only for published events");
        }

        // ========================================================
        // CHECK REGISTRATION DEADLINE
        // ========================================================

        if (event.getRegistrationDeadline() != null
                && LocalDateTime.now()
                        .isAfter(event.getRegistrationDeadline())) {

            throw new RuntimeException(
                    "Registration deadline has passed");
        }

        // ========================================================
        // FREE EVENT ONLY
        // ========================================================

        if (event.getPaymentType() != PaymentType.FREE) {

            throw new RuntimeException(
                    "Paid event registration will be handled through payment");
        }

        // ========================================================
        // PREVENT DUPLICATE REGISTRATION
        // ========================================================

        if (registrationRepository.existsByEventIdAndStudentId(
                eventId,
                student.getId())) {

            throw new RuntimeException(
                    "Student is already registered for this event");
        }

        // ========================================================
        // CAPACITY CHECK
        // ========================================================

        if (event.getCapacityType() == CapacityType.LIMITED) {

            if (event.getCapacity() == null
                    || event.getCapacity() <= 0) {

                throw new RuntimeException(
                        "Event capacity is invalid");
            }

            long registeredCount =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.REGISTERED);

            if (registeredCount >= event.getCapacity()) {

                throw new RuntimeException(
                        "Event registration capacity is full");
            }
        }

        // ========================================================
        // CREATE REGISTRATION
        // ========================================================

        EventRegistration registration =
                new EventRegistration();

        registration.setEvent(event);
        registration.setStudent(student);

        registration.setStatus(
                EventRegistrationStatus.REGISTERED);

        registration.setRegisteredAt(
                LocalDateTime.now());

        registration.setConfirmedAt(
                LocalDateTime.now());

        EventRegistration saved =
                registrationRepository.save(registration);

        return toResponse(saved);
    }

    // ============================================================
    // GET MY REGISTRATIONS
    // ============================================================

    @Transactional(readOnly = true)
    public java.util.List<EventRegistrationResponse> getMyRegistrations(
            Long userId) {

        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Student profile not found"));

        return registrationRepository
                .findByStudentIdOrderByRegisteredAtDesc(
                        student.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // RESPONSE MAPPER
    // ============================================================

    private EventRegistrationResponse toResponse(
            EventRegistration registration) {

        Student student = registration.getStudent();

        return new EventRegistrationResponse(
                registration.getId(),
                registration.getEvent().getId(),
                student.getId(),

                student.getUser().getName(),
                student.getUser().getEmail(),
                student.getUser().getPhoneNumber(),

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