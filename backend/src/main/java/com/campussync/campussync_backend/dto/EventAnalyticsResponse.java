package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;

public record EventAnalyticsResponse(
        Long eventId,
        String eventTitle,
        long totalParticipants,
        BigDecimal grossRevenue,
        BigDecimal completedRefunds,
        BigDecimal netRevenue
) {
}