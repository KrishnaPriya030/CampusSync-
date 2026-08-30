
package com.campussync.campussync_backend.dto;

public record DepartmentResponse(
        Long id,
        String name,
        String code,
        Boolean active
) {
}