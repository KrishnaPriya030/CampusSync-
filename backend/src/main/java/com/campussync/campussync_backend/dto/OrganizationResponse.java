package com.campussync.campussync_backend.dto;

import com.campussync.campussync_backend.enums.OrganizationType;

public record OrganizationResponse(

        Long id,

        String name,

        String code,

        OrganizationType organizationType,

        Long departmentId,

        String departmentName,

        String description,

        boolean active

) {
}