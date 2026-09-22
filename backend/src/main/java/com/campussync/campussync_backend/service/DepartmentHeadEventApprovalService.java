package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.DepartmentHead;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.Organization;
import com.campussync.campussync_backend.enums.EventScope;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.repository.DepartmentHeadRepository;
import com.campussync.campussync_backend.repository.EventRepository;

@Service
public class DepartmentHeadEventApprovalService {

    private final EventRepository eventRepository;
    private final DepartmentHeadRepository departmentHeadRepository;

    public DepartmentHeadEventApprovalService(
            EventRepository eventRepository,
            DepartmentHeadRepository departmentHeadRepository) {

        this.eventRepository = eventRepository;
        this.departmentHeadRepository = departmentHeadRepository;
    }

    // ============================================================
    // APPROVE EVENT
    // ============================================================

    @Transactional
    public EventResponse approve(
            Long userId,
            Long eventId) {

        DepartmentHead head =
                getDepartmentHeadByUserId(userId);

        Event event =
                getEvent(eventId);

        validateDepartmentEvent(head, event);

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

        DepartmentHead head =
                getDepartmentHeadByUserId(userId);

        Event event =
                getEvent(eventId);

        validateDepartmentEvent(head, event);

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
    // OWNERSHIP / SCOPE VALIDATION
    // ============================================================

    private void validateDepartmentEvent(
            DepartmentHead head,
            Event event) {

        /*
         * The event itself must explicitly be
         * DEPARTMENT scoped.
         *
         * An ORGANIZATION-scoped event must never
         * be approved by a Department Head.
         */
        if (event.getScope() != EventScope.DEPARTMENT) {

            throw new RuntimeException(
                    "This event is not department-scoped");
        }

        Organization organization =
                event.getOrganizer()
                        .getOrganization();

        if (organization == null) {

            throw new RuntimeException(
                    "Event organization not found");
        }

        /*
         * A Department-scoped event requires the
         * Organizer's organization to belong to
         * a department.
         */
        if (organization.getDepartment() == null) {

            throw new RuntimeException(
                    "This department-scoped event has no associated department");
        }

        /*
         * The Department Head can approve only events
         * belonging to their own department.
         */
        if (head.getDepartment() == null) {

            throw new RuntimeException(
                    "Department Head is not associated with a department");
        }

        if (!organization.getDepartment()
                .getId()
                .equals(head.getDepartment().getId())) {

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