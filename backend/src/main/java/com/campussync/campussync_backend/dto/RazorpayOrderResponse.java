package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;

public record RazorpayOrderResponse(
        Long registrationId,
        Long eventId,
        BigDecimal amount,
        String currency,
        String razorpayOrderId,
        String razorpayKeyId
) {
}