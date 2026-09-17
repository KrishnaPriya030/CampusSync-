package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.Organization;
import com.campussync.campussync_backend.entity.OrganizationHead;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.OrganizationHeadRepository;

@Service
public class OrganizationHeadEventApprovalService {

    private final EventRepository eventRepository;
    private final OrganizationHeadRepository organizationHeadRepository;

    public OrganizationHeadEventApprovalService(
            EventRepository eventRepository,
            OrganizationHeadRepository organizationHeadRepository) {

        this.eventRepository = eventRepository;
        this.organizationHeadRepository =
                organizationHeadRepository;
    }

    // ============================================================
    // APPROVE EVENT
    // ============================================================

    @Transactional
    public EventResponse approve(
            Long userId,
            Long eventId) {

        OrganizationHead head =
                getOrganizationHeadByUserId(userId);

        Event event =
                getEvent(eventId);

        validateOrganizationEvent(head, event);

        if (event.getStatus() !=
                EventStatus.PENDING_APPROVAL) {

            throw new RuntimeException(
                    "Only events pending approval can be approved");
        }

        event.setStatus(EventStatus.APPROVED);

        event.setApprovedBy(userId);

        event.setApprovedAt(
                LocalDateTime.now());

        event.setRejectionReason(null);

        event.setUpdatedAt(
                LocalDateTime.now());

        return toResponse(
                eventRepository.save(event));
    }

    // ============================================================
    // REJECT EVENT
    // ============================================================

    @Transactional
    public EventResponse reject(
            Long userId,
            Long eventId,
            String reason) {

        OrganizationHead head =
                getOrganizationHeadByUserId(userId);

        Event event =
                getEvent(eventId);

        validateOrganizationEvent(head, event);

        if (event.getStatus() !=
                EventStatus.PENDING_APPROVAL) {

            throw new RuntimeException(
                    "Only events pending approval can be rejected");
        }

        if (reason == null ||
                reason.trim().isEmpty()) {

            throw new RuntimeException(
                    "Rejection reason is required");
        }

        event.setStatus(EventStatus.REJECTED);

        event.setApprovedBy(null);

        event.setApprovedAt(null);

        event.setRejectionReason(
                reason.trim());

        event.setUpdatedAt(
                LocalDateTime.now());

        return toResponse(
                eventRepository.save(event));
    }

    // ============================================================
    // GET EVENT
    // ============================================================

    private Event getEvent(Long eventId) {

        return eventRepository
                .findByIdAndDeletedFalse(eventId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Event not found"));
    }

    // ============================================================
    // ORGANIZATION HEAD LOOKUP
    // ============================================================

    private OrganizationHead getOrganizationHeadByUserId(
            Long userId) {

        return organizationHeadRepository
                .findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Organization Head account not found"));
    }

    // ============================================================
    // OWNERSHIP / SCOPE VALIDATION
    // ============================================================

    private void validateOrganizationEvent(
            OrganizationHead head,
            Event event) {

        Organization eventOrganization =
                event.getOrganizer()
                        .getOrganization();

        if (eventOrganization == null) {

            throw new RuntimeException(
                    "Event organization not found");
        }

        if (!eventOrganization.getId()
                .equals(head.getOrganization().getId())) {

            throw new RuntimeException(
                    "You are not authorized to approve this event");
        }
    }

    // ============================================================
    // RESPONSE MAPPING
    // ============================================================

    private EventResponse toResponse(
            Event event) {

        var organizer =
                event.getOrganizer();

        return new EventResponse(
                event.getId(),

                organizer.getId(),
                organizer.getUser().getName(),

                organizer.getOrganization().getId(),
                organizer.getOrganization().getName(),

                event.getTitle(),
                event.getDescription(),
                event.getVenue(),

                event.getStartDateTime(),
                event.getEndDateTime(),
                event.getRegistrationDeadline(),

                event.getCapacityType(),
                event.getCapacity(),

                event.getPaymentType(),
                event.getRegistrationFee(),

                event.getRefundPolicy(),

                event.isAttendanceEnabled(),
                event.isCertificateEnabled(),

                event.getStatus()
        );
    }
}