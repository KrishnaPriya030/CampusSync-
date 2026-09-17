package com.campussync.campussync_backend.dto;

import jakarta.validation.constraints.NotBlank;

public record DepartmentRequest(

        @NotBlank
        String name,

        @NotBlank
        String code

) {
}