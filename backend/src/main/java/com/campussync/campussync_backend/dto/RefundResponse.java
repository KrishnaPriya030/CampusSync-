package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.RefundStatus;

public record RefundResponse(

        Long refundId,

        Long paymentId,

        Long registrationId,

        Long eventId,

        Long studentId,

        String studentName,

        String studentEmail,

        BigDecimal amount,

        String reason,

        RefundStatus status,

        LocalDateTime requestedAt,

        LocalDateTime processedAt,

        String processingNote

) {
}