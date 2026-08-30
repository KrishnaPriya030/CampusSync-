package com.campussync.campussync_backend.dto;

public record OrganizerResponse(

        Long id,

        Long userId,

        String name,

        String email,

        String phoneNumber,

        Long organizationId,

        String organizationName,

        String designation,

        String accountStatus

) {
}