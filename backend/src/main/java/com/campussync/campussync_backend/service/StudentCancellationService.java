package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.EventRegistrationResponse;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;

@Service
public class StudentCancellationService {

    private final EventRegistrationRepository registrationRepository;

    public StudentCancellationService(
            EventRegistrationRepository registrationRepository) {
        this.registrationRepository = registrationRepository;
    }

    @Transactional
    public EventRegistrationResponse cancelRegistration(
            Long userId,
            Long registrationId) {

        EventRegistration registration =
                registrationRepository.findById(registrationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Registration not found"));

        // Make sure the registration belongs to the logged-in student
        if (!registration.getStudent().getUser().getId().equals(userId)) {
            throw new RuntimeException(
                    "You can cancel only your own registration");
        }

        // Only a registered booking can be cancelled
        if (registration.getStatus()
                != EventRegistrationStatus.REGISTERED) {

            throw new RuntimeException(
                    "Registration cannot be cancelled in its current status");
        }

        // Do not allow cancellation after the event has started
        if (!LocalDateTime.now()
                .isBefore(registration.getEvent().getStartDateTime())) {

            throw new RuntimeException(
                    "Registration cannot be cancelled after the event has started");
        }

        // First version: FREE event cancellation
        if (registration.getEvent().getPaymentType() == null
                || !registration.getEvent().getPaymentType()
                        .name().equals("FREE")) {

            throw new RuntimeException(
                    "Paid event cancellation will be handled through the refund flow");
        }

        registration.setStatus(EventRegistrationStatus.CANCELLED);

        EventRegistration saved =
                registrationRepository.save(registration);

        return toResponse(saved);
    }

    private EventRegistrationResponse toResponse(
            EventRegistration registration) {

        var student = registration.getStudent();

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