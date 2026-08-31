package com.campussync.campussync_backend.dto;

public record StudentListResponse(

        Long id,

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

        String status,

        String accountStatus

) {
}