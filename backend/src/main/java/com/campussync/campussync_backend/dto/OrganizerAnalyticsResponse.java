package com.campussync.campussync_backend.dto;

import java.math.BigDecimal;
import java.util.List;

public record OrganizerAnalyticsResponse(
        long totalEvents,
        long totalParticipants,
        BigDecimal grossRevenue,
        BigDecimal completedRefunds,
        BigDecimal netRevenue,
        List<EventAnalyticsResponse> events
) {
}