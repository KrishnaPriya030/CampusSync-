package com.campussync.campussync_backend.dto;

public record CreateOrganizerResponse(

        Long userId,

        Long organizerId,

        String name,

        String email,

        String activationLink,

        String organizationName,

        String designation

) {
}