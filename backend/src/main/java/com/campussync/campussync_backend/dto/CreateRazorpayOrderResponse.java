package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;

public record CreateRazorpayOrderResponse(

        Long registrationId,

        Long eventId,

        String razorpayOrderId,

        String razorpayKeyId,

        BigDecimal amount,

        String currency

) {
}