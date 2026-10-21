package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.EventAnalyticsResponse;
import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.dto.OrganizerAnalyticsResponse;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.entity.Refund;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.enums.RefundStatus;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.campussync.campussync_backend.repository.RefundRepository;

@Service
public class OrganizerAnalyticsService {

    private final OrganizerEventService eventService;
    private final EventRegistrationRepository registrationRepository;
    private final PaymentRepository paymentRepository;
    private final RefundRepository refundRepository;

    public OrganizerAnalyticsService(
            OrganizerEventService eventService,
            EventRegistrationRepository registrationRepository,
            PaymentRepository paymentRepository,
            RefundRepository refundRepository) {

        this.eventService = eventService;
        this.registrationRepository = registrationRepository;
        this.paymentRepository = paymentRepository;
        this.refundRepository = refundRepository;
    }

    @Transactional(readOnly = true)
    public OrganizerAnalyticsResponse getAnalytics(Long userId) {

        // Only return events belonging to this organizer.
        List<EventResponse> organizerEvents =
                eventService.getMyEvents(userId);

        long totalParticipants = 0L;

        BigDecimal grossRevenue = BigDecimal.ZERO;
        BigDecimal completedRefunds = BigDecimal.ZERO;

        List<EventAnalyticsResponse> eventAnalytics =
                new ArrayList<>();

        for (EventResponse event : organizerEvents) {

            Long eventId = event.id();

            // Count confirmed registrations only.
            long participants =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.REGISTERED);

            totalParticipants += participants;

            BigDecimal eventGross = BigDecimal.ZERO;
            BigDecimal eventRefunds = BigDecimal.ZERO;

            // Calculate captured payments for this event.
            List<Payment> payments =
                    paymentRepository
                            .findByRegistrationEventIdOrderByCreatedAtDesc(
                                    eventId);

            for (Payment payment : payments) {

                PaymentStatus status = payment.getStatus();

                /*
                 * PAID, REFUND_PENDING and REFUNDED indicate
                 * a payment that was successfully captured.
                 *
                 * Pending and failed payments are excluded.
                 * Refunds are deducted separately below.
                 */
                if (status == PaymentStatus.PAID
                        || status == PaymentStatus.REFUND_PENDING
                        || status == PaymentStatus.REFUNDED) {

                    if (payment.getAmount() != null) {
                        eventGross =
                                eventGross.add(payment.getAmount());
                    }
                }
            }

            // Deduct refunds only when their status is COMPLETED.
            List<Refund> refunds =
                    refundRepository
                            .findByPaymentRegistrationEventIdOrderByRequestedAtDesc(
                                    eventId);

            for (Refund refund : refunds) {

                if (refund.getStatus() == RefundStatus.COMPLETED
                        && refund.getAmount() != null) {

                    eventRefunds =
                            eventRefunds.add(refund.getAmount());
                }
            }

            BigDecimal eventNet =
                    eventGross.subtract(eventRefunds);

            grossRevenue = grossRevenue.add(eventGross);
            completedRefunds =
                    completedRefunds.add(eventRefunds);

            eventAnalytics.add(
                    new EventAnalyticsResponse(
                            eventId,
                            event.title(),
                            participants,
                            eventGross,
                            eventRefunds,
                            eventNet
                    )
            );
        }

        BigDecimal netRevenue =
                grossRevenue.subtract(completedRefunds);

        return new OrganizerAnalyticsResponse(
                organizerEvents.size(),
                totalParticipants,
                grossRevenue,
                completedRefunds,
                netRevenue,
                eventAnalytics
        );
    }
}

