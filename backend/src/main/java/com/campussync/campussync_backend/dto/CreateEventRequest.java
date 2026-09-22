
package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventScope;
import com.campussync.campussync_backend.enums.PaymentType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateEventRequest(

        @NotBlank(message = "Title is required")
        String title,

        @NotBlank(message = "Description is required")
        String description,

        @NotBlank(message = "Venue is required")
        String venue,

        @NotNull(message = "Start date and time is required")
        LocalDateTime startDateTime,

        @NotNull(message = "End date and time is required")
        LocalDateTime endDateTime,

        @NotNull(message = "Registration deadline is required")
        LocalDateTime registrationDeadline,

        @NotNull(message = "Event scope is required")
        EventScope scope,

        @NotNull(message = "Capacity type is required")
        CapacityType capacityType,

        Integer capacity,

        @NotNull(message = "Payment type is required")
        PaymentType paymentType,

        @NotNull(message = "Registration fee is required")
        BigDecimal registrationFee,

        String refundPolicy,

        boolean attendanceEnabled,

        boolean certificateEnabled,

        Long certificateTemplateId
) {
}

