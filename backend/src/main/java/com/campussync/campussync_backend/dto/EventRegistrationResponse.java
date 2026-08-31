package com.campussync.campussync_backend.dto;

import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.EventRegistrationStatus;

public record EventRegistrationResponse(

        Long registrationId,

        Long eventId,

        Long studentId,

        String name,

        String email,

        String phoneNumber,

        String registerNumber,

        Long departmentId,

        String departmentName,

        Long branchId,

        String branchName,

        String programme,

        Integer admissionYear,

        Integer semester,

        Integer graduationYear,

        boolean internal,

        EventRegistrationStatus status,

        LocalDateTime registeredAt

) {
}