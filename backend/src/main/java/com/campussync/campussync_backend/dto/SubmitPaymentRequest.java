package com.campussync.campussync_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SubmitPaymentRequest(

        @NotBlank(message = "Payment reference is required")
        @Size(max = 255, message = "Payment reference cannot exceed 255 characters")
        String paymentReference

) {}