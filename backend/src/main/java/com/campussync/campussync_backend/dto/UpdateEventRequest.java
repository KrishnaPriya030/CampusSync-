package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.PaymentType;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record UpdateEventRequest(

        @NotBlank
        String title,

        @NotBlank
        String description,

        @NotBlank
        String venue,

        @NotNull
        LocalDateTime startDateTime,

        @NotNull
        LocalDateTime endDateTime,

        @NotNull
        LocalDateTime registrationDeadline,

        @NotNull
        CapacityType capacityType,

        Integer capacity,

        @NotNull
        PaymentType paymentType,

        @NotNull
        @DecimalMin(value = "0.00")
        BigDecimal registrationFee,

        String refundPolicy,

        boolean attendanceEnabled,

        boolean certificateEnabled

) {
}