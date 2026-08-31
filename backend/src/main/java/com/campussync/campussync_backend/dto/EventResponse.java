package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.PaymentType;

public record EventResponse(

        Long id,

        Long organizerId,

        String organizerName,

        Long organizationId,

        String organizationName,

        String title,

        String description,

        String venue,

        LocalDateTime startDateTime,

        LocalDateTime endDateTime,

        LocalDateTime registrationDeadline,

        CapacityType capacityType,

        Integer capacity,

        PaymentType paymentType,

        BigDecimal registrationFee,

        String refundPolicy,

        boolean attendanceEnabled,

        boolean certificateEnabled,

        EventStatus status

) {
}