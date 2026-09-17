package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.EventRegistrationResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.EventStatus;
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

        // Find the student belonging to the logged-in user
        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException("Student profile not found"));

        // Find the event
        Event event = eventRepository.findByIdAndDeletedFalse(eventId)
                .orElseThrow(() ->
                        new RuntimeException("Event not found"));

        // Only published events can be registered for
        if (event.getStatus() != EventStatus.PUBLISHED) {
            throw new RuntimeException(
                    "Registration is available only for published events");
        }

        // Check registration deadline
        if (event.getRegistrationDeadline() != null
                && LocalDateTime.now()
                        .isAfter(event.getRegistrationDeadline())) {

            throw new RuntimeException(
                    "Registration deadline has passed");
        }

        // Prevent duplicate registration
        if (registrationRepository.existsByEventIdAndStudentId(
                eventId,
                student.getId())) {

            throw new RuntimeException(
                    "Student is already registered for this event");
        }

        // Check capacity for limited events
        if (event.getCapacityType() != null
                && event.getCapacityType().name().equals("LIMITED")) {

            long registeredCount =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.REGISTERED);

            if (event.getCapacity() != null
                    && registeredCount >= event.getCapacity()) {

                throw new RuntimeException(
                        "Event registration capacity is full");
            }
        }

        // First version: handle FREE events only
        if (event.getPaymentType() == null
                || !event.getPaymentType().name().equals("FREE")) {

            throw new RuntimeException(
                    "Paid event registration will be handled through payment");
        }

        // Create registration
        EventRegistration registration = new EventRegistration();

        registration.setEvent(event);
        registration.setStudent(student);
        registration.setStatus(EventRegistrationStatus.REGISTERED);
        registration.setRegisteredAt(LocalDateTime.now());
        registration.setConfirmedAt(LocalDateTime.now());

        EventRegistration saved =
                registrationRepository.save(registration);

        return toResponse(saved);
    }

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
    @Transactional(readOnly = true)
public java.util.List<EventRegistrationResponse> getMyRegistrations(
        Long userId) {

    Student student = studentRepository.findByUserId(userId)
            .orElseThrow(() ->
                    new RuntimeException("Student profile not found"));

    return registrationRepository
            .findByStudentIdOrderByRegisteredAtDesc(student.getId())
            .stream()
            .map(this::toResponse)
            .toList();
}
}