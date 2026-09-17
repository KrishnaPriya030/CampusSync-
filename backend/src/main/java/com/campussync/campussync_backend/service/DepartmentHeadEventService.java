package com.campussync.campussync_backend.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.DepartmentHead;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.repository.DepartmentHeadRepository;
import com.campussync.campussync_backend.repository.EventRepository;

@Service
public class DepartmentHeadEventService {

    private final EventRepository eventRepository;
    private final DepartmentHeadRepository departmentHeadRepository;

    public DepartmentHeadEventService(
            EventRepository eventRepository,
            DepartmentHeadRepository departmentHeadRepository) {

        this.eventRepository = eventRepository;
        this.departmentHeadRepository = departmentHeadRepository;
    }

    // ============================================================
    // GET ALL DEPARTMENT EVENTS
    // ============================================================

    public List<EventResponse> getDepartmentEvents(Long userId) {

        DepartmentHead head =
                getDepartmentHeadByUserId(userId);

        Long departmentId =
                head.getDepartment().getId();

        return eventRepository
                .findByOrganizerOrganizationDepartmentIdAndDeletedFalseOrderByCreatedAtDesc(
                        departmentId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // GET PENDING DEPARTMENT EVENTS
    // ============================================================

    public List<EventResponse> getPendingEvents(Long userId) {

        DepartmentHead head =
                getDepartmentHeadByUserId(userId);

        Long departmentId =
                head.getDepartment().getId();

        return eventRepository
                .findByOrganizerOrganizationDepartmentIdAndStatusAndDeletedFalseOrderByCreatedAtDesc(
                        departmentId,
                        EventStatus.PENDING_APPROVAL)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // DEPARTMENT HEAD LOOKUP
    // ============================================================

    private DepartmentHead getDepartmentHeadByUserId(
            Long userId) {

        return departmentHeadRepository
                .findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Department Head account not found"));
    }

    // ============================================================
    // RESPONSE MAPPING
    // ============================================================

    private EventResponse toResponse(Event event) {

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