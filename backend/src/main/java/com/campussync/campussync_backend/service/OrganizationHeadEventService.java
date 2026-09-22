package com.campussync.campussync_backend.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.OrganizationHead;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.OrganizationHeadRepository;

@Service
public class OrganizationHeadEventService {

    private final OrganizationHeadRepository organizationHeadRepository;
    private final EventRepository eventRepository;

    public OrganizationHeadEventService(
            OrganizationHeadRepository organizationHeadRepository,
            EventRepository eventRepository) {

        this.organizationHeadRepository = organizationHeadRepository;
        this.eventRepository = eventRepository;
    }

    // ============================================================
    // GET ALL ORGANIZATION EVENTS
    // ============================================================

    public List<EventResponse> getOrganizationEvents(Long userId) {

        OrganizationHead head =
                organizationHeadRepository
                        .findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization Head profile not found"));

        Long organizationId =
                head.getOrganization().getId();

        return eventRepository
                .findByOrganizerOrganizationIdAndDeletedFalseOrderByCreatedAtDesc(
                        organizationId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // GET PENDING APPROVAL EVENTS
    // ============================================================

    public List<EventResponse> getPendingEvents(Long userId) {

        OrganizationHead head =
                organizationHeadRepository
                        .findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization Head profile not found"));

        Long organizationId =
                head.getOrganization().getId();

        return eventRepository
                .findByOrganizerOrganizationIdAndStatusAndDeletedFalseOrderByCreatedAtDesc(
                        organizationId,
                        EventStatus.PENDING_APPROVAL)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // EVENT RESPONSE MAPPING
    // ============================================================

    private EventResponse toResponse(Event event) {

        return new EventResponse(
                event.getId(),

                event.getOrganizer().getId(),
                event.getOrganizer().getUser().getName(),

                event.getOrganizer().getOrganization().getId(),
                event.getOrganizer().getOrganization().getName(),

                event.getTitle(),
                event.getDescription(),
                event.getVenue(),

                event.getStartDateTime(),
                event.getEndDateTime(),
                event.getRegistrationDeadline(),

                // NEW: Event scope
                event.getScope(),

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