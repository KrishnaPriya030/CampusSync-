package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.PaymentStatus;

public record PaymentResponse(

        Long paymentId,

        Long registrationId,

        Long eventId,

        Long studentId,

        String studentName,

        String studentEmail,

        BigDecimal amount,

        PaymentStatus status,

        String paymentReference,

        LocalDateTime createdAt,

        LocalDateTime paidAt

) {
}   