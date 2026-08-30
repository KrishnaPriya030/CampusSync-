package com.campussync.campussync_backend.dto;

public record BranchResponse(
        Long id,
        String name,
        String code,
        Boolean active
) {
}