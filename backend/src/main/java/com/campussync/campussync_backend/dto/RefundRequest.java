
package com.campussync.campussync_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RefundRequest(

        @NotBlank
        @Size(max = 250, message = "Refund reason cannot exceed 250 characters")
        String reason

) {}
