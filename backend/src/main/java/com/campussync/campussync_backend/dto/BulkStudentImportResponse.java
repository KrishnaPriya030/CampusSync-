package com.campussync.campussync_backend.dto;

import java.util.List;

public record BulkStudentImportResponse(
        int totalRows,
        int successful,
        int failed,
        List<String> errors
) {
}