package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.CreateEventRequest;
import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.dto.UpdateEventRequest;
import com.campussync.campussync_backend.entity.CertificateTemplate;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.Organizer;
import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventScope;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.repository.CertificateTemplateRepository;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.OrganizerRepository;
import com.campussync.campussync_backend.repository.OrganizationRepository;

@Service
public class OrganizerEventService {

    private final EventRepository eventRepository;
    private final OrganizerRepository organizerRepository;
    private final OrganizationRepository organizationRepository;
    private final CertificateTemplateRepository certificateTemplateRepository;
    private final NotificationService notificationService;

    public OrganizerEventService(
            EventRepository eventRepository,
            OrganizerRepository organizerRepository,
            OrganizationRepository organizationRepository,
            CertificateTemplateRepository certificateTemplateRepository,
            NotificationService notificationService) {

        this.eventRepository = eventRepository;
        this.organizerRepository = organizerRepository;
        this.organizationRepository = organizationRepository;
        this.certificateTemplateRepository =
                certificateTemplateRepository;
        this.notificationService = notificationService;
    }

    // ============================================================
    // CREATE
    // ============================================================

    @Transactional
    public EventResponse create(
            Long userId,
            CreateEventRequest request) {

        validateEventRequest(
                request.capacityType(),
                request.capacity(),
                request.paymentType(),
                request.registrationFee(),
                request.startDateTime(),
                request.endDateTime(),
                request.registrationDeadline(),
                request.attendanceEnabled(),
                request.certificateEnabled()
        );

        Organizer organizer =
                getOrganizerByUserId(userId);

        // ========================================================
        // EVENT SCOPE VALIDATION
        // ========================================================

        validateEventScope(
                organizer,
                request.scope()
        );

        Event event = new Event();

        event.setOrganizer(organizer);
        event.setTitle(request.title());
        event.setDescription(request.description());
        event.setVenue(request.venue());

        event.setStartDateTime(
                request.startDateTime());

        event.setEndDateTime(
                request.endDateTime());

        event.setRegistrationDeadline(
                request.registrationDeadline());

        event.setScope(
                request.scope());

        event.setCapacityType(
                request.capacityType());

        event.setCapacity(
                request.capacityType() ==
                        CapacityType.LIMITED
                        ? request.capacity()
                        : null);

        event.setPaymentType(
                request.paymentType());

        event.setRegistrationFee(
                request.paymentType() ==
                        PaymentType.PAID
                        ? request.registrationFee()
                        : BigDecimal.ZERO);

        event.setRefundPolicy(
                request.refundPolicy());

        event.setAttendanceEnabled(
                request.attendanceEnabled());

        event.setCertificateEnabled(
                request.certificateEnabled());

        // ========================================================
        // CERTIFICATE TEMPLATE
        // ========================================================

        if (request.certificateEnabled()) {

            if (request.certificateTemplateId() == null) {

                throw new RuntimeException(
                        "Certificate template is required when certificates are enabled");
            }

            CertificateTemplate template =
                    certificateTemplateRepository
                            .findById(
                                    request.certificateTemplateId())
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Certificate template not found"));

            event.setCertificateTemplate(template);

        } else {

            event.setCertificateTemplate(null);
        }

        event.setStatus(
                EventStatus.DRAFT);

        event.setApprovedBy(null);
        event.setApprovedAt(null);
        event.setRejectionReason(null);

        event.setDeleted(false);

        event.setCreatedAt(
                LocalDateTime.now());

        event.setUpdatedAt(
                LocalDateTime.now());

        return toResponse(
                eventRepository.save(event));
    }

    // ============================================================
    // GET MY EVENTS
    // ============================================================

    @Transactional(readOnly = true)
    public List<EventResponse> getMyEvents(
            Long userId) {

        Organizer organizer =
                getOrganizerByUserId(userId);

        return eventRepository
                .findByOrganizerIdAndDeletedFalseOrderByCreatedAtDesc(
                        organizer.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // GET EVENT
    // ============================================================

    @Transactional(readOnly = true)
    public EventResponse getById(
            Long userId,
            Long eventId) {

        Event event =
                getOwnedEvent(userId, eventId);

        return toResponse(event);
    }

    // ============================================================
    // UPDATE
    // ============================================================

    @Transactional
    public EventResponse update(
            Long userId,
            Long eventId,
            UpdateEventRequest request) {

        validateEventRequest(
                request.capacityType(),
                request.capacity(),
                request.paymentType(),
                request.registrationFee(),
                request.startDateTime(),
                request.endDateTime(),
                request.registrationDeadline(),
                request.attendanceEnabled(),
                request.certificateEnabled()
        );

        Event event =
                getOwnedEvent(userId, eventId);

        /*
         * DRAFT and REJECTED events can be edited normally.
         *
         * PUBLISHED events can also be updated because
         * registered students must be informed when
         * published event details change.
         *
         * PENDING_APPROVAL and APPROVED events cannot be
         * edited directly.
         */
        if (event.getStatus() != EventStatus.DRAFT
                && event.getStatus() != EventStatus.REJECTED
                && event.getStatus() != EventStatus.PUBLISHED) {

            throw new RuntimeException(
                    "Only draft, rejected, or published events can be edited");
        }

        boolean wasPublished =
                event.getStatus() == EventStatus.PUBLISHED;

        validateEventScope(
                event.getOrganizer(),
                request.scope()
        );

        event.setTitle(request.title());
        event.setDescription(request.description());
        event.setVenue(request.venue());

        event.setStartDateTime(
                request.startDateTime());

        event.setEndDateTime(
                request.endDateTime());

        event.setRegistrationDeadline(
                request.registrationDeadline());

        event.setScope(
                request.scope());

        event.setCapacityType(
                request.capacityType());

        event.setCapacity(
                request.capacityType() ==
                        CapacityType.LIMITED
                        ? request.capacity()
                        : null);

        event.setPaymentType(
                request.paymentType());

        event.setRegistrationFee(
                request.paymentType() ==
                        PaymentType.PAID
                        ? request.registrationFee()
                        : BigDecimal.ZERO);

        event.setRefundPolicy(
                request.refundPolicy());

        event.setAttendanceEnabled(
                request.attendanceEnabled());

        event.setCertificateEnabled(
                request.certificateEnabled());

        // ========================================================
        // CERTIFICATE TEMPLATE
        // ========================================================

        if (request.certificateEnabled()) {

            if (request.certificateTemplateId() == null) {

                throw new RuntimeException(
                        "Certificate template is required when certificates are enabled");
            }

            CertificateTemplate template =
                    certificateTemplateRepository
                            .findById(
                                    request.certificateTemplateId())
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Certificate template not found"));

            event.setCertificateTemplate(template);

        } else {

            event.setCertificateTemplate(null);
        }

        event.setUpdatedAt(
                LocalDateTime.now());

        Event savedEvent =
                eventRepository.save(event);

        // ========================================================
        // PUBLISHED EVENT UPDATED NOTIFICATION
        // ========================================================

        if (wasPublished) {

            notificationService.notifyRegisteredStudents(
                    savedEvent.getId(),
                    "Event Updated",
                    "The event \""
                            + savedEvent.getTitle()
                            + "\" has been updated. Please check the latest event details.",
                    NotificationType.EVENT_UPDATED,
                    savedEvent
            );
        }

        return toResponse(savedEvent);
    }

    // ============================================================
    // SUBMIT FOR APPROVAL
    // ============================================================

    @Transactional
    public EventResponse submitForApproval(
            Long userId,
            Long eventId) {

        Event event =
                getOwnedEvent(userId, eventId);

        if (event.getStatus() != EventStatus.DRAFT
                && event.getStatus() != EventStatus.REJECTED) {

            throw new RuntimeException(
                    "Only draft or rejected events can be submitted for approval");
        }

        /*
         * Re-check the event timing before sending it
         * to a Department Head or Organization Head.
         */
        if (event.getRegistrationDeadline()
                .isAfter(event.getStartDateTime())) {

            throw new RuntimeException(
                    "Registration deadline must be before event start");
        }

        /*
         * Make sure an existing/legacy event has a valid scope
         * before entering an approval cycle.
         */
        if (event.getScope() == null) {

            throw new RuntimeException(
                    "Event scope must be selected before submitting for approval");
        }

        validateEventScope(
                event.getOrganizer(),
                event.getScope()
        );

        /*
         * If certificates are enabled, make sure the event
         * has a certificate template before approval.
         */
        if (event.isCertificateEnabled()
                && event.getCertificateTemplate() == null) {

            throw new RuntimeException(
                    "Certificate template is required when certificates are enabled");
        }

        /*
         * A new approval cycle starts here.
         */
        event.setStatus(
                EventStatus.PENDING_APPROVAL);

        event.setApprovedBy(null);
        event.setApprovedAt(null);
        event.setRejectionReason(null);

        event.setUpdatedAt(
                LocalDateTime.now());

        return toResponse(
                eventRepository.save(event));
    }

    // ============================================================
    // DELETE EVENT
    // ============================================================

    @Transactional
    public void delete(
            Long userId,
            Long eventId) {

        Event event =
                getOwnedEvent(userId, eventId);

        /*
         * Soft delete.
         *
         * We don't physically delete the event because
         * future registrations, payments, refunds,
         * attendance and certificates may reference it.
         */
        event.setDeleted(true);
        event.setUpdatedAt(
                LocalDateTime.now());

        eventRepository.save(event);
    }

    // ============================================================
    // CANCEL EVENT
    // ============================================================

    @Transactional
    public EventResponse cancel(
            Long userId,
            Long eventId) {

        Event event =
                getOwnedEvent(userId, eventId);

        /*
         * Only published events can be cancelled.
         */
        if (event.getStatus() != EventStatus.PUBLISHED) {

            throw new RuntimeException(
                    "Only published events can be cancelled");
        }

        event.setStatus(
                EventStatus.CANCELLED);

        event.setUpdatedAt(
                LocalDateTime.now());

        Event savedEvent =
                eventRepository.save(event);

        // ========================================================
        // EVENT CANCELLED NOTIFICATION
        // ========================================================

        notificationService.notifyRegisteredStudents(
                savedEvent.getId(),
                "Event Cancelled",
                "The event \""
                        + savedEvent.getTitle()
                        + "\" has been cancelled.",
                NotificationType.EVENT_CANCELLED,
                savedEvent
        );

        return toResponse(savedEvent);
    }

    // ============================================================
    // PUBLISH
    // ============================================================

    @Transactional
    public EventResponse publish(
            Long userId,
            Long eventId) {

        Event event =
                getOwnedEvent(userId, eventId);

        /*
         * An Organizer can publish only after the
         * appropriate Head has approved the event.
         */
        if (event.getStatus() != EventStatus.APPROVED) {

            throw new RuntimeException(
                    "Only approved events can be published");
        }

        if (event.getScope() == null) {

            throw new RuntimeException(
                    "Event scope is missing");
        }

        validateEventScope(
                event.getOrganizer(),
                event.getScope()
        );

        if (event.getRegistrationDeadline()
                .isAfter(event.getStartDateTime())) {

            throw new RuntimeException(
                    "Registration deadline must be before event start");
        }

        if (event.isCertificateEnabled()
                && event.getCertificateTemplate() == null) {

            throw new RuntimeException(
                    "Certificate template is required for published events");
        }

        event.setStatus(
                EventStatus.PUBLISHED);

        event.setUpdatedAt(
                LocalDateTime.now());

        Event savedEvent =
                eventRepository.save(event);

        // ========================================================
        // NEW EVENT NOTIFICATION
        // ========================================================

        notificationService.notifyAllUsers(
                "New Event Available",
                "A new event \""
                        + savedEvent.getTitle()
                        + "\" has been published.",
                NotificationType.NEW_EVENT,
                savedEvent
        );

        return toResponse(savedEvent);
    }

    // ============================================================
    // VALIDATION
    // ============================================================

    private void validateEventRequest(
            CapacityType capacityType,
            Integer capacity,
            PaymentType paymentType,
            BigDecimal registrationFee,
            LocalDateTime startDateTime,
            LocalDateTime endDateTime,
            LocalDateTime registrationDeadline,
            boolean attendanceEnabled,
            boolean certificateEnabled) {

        if (!endDateTime.isAfter(startDateTime)) {

            throw new RuntimeException(
                    "Event end time must be after event start time");
        }

        if (!registrationDeadline
                .isBefore(startDateTime)) {

            throw new RuntimeException(
                    "Registration deadline must be before event start");
        }

        if (capacityType ==
                CapacityType.LIMITED) {

            if (capacity == null ||
                    capacity <= 0) {

                throw new RuntimeException(
                        "Capacity must be greater than zero for limited events");
            }
        }

        if (capacityType ==
                CapacityType.UNLIMITED) {

            /*
             * Capacity is ignored for unlimited events.
             */
        }

        if (paymentType ==
                PaymentType.PAID) {

            if (registrationFee == null ||
                    registrationFee
                            .compareTo(BigDecimal.ZERO) <= 0) {

                throw new RuntimeException(
                        "Registration fee must be greater than zero for paid events");
            }
        }

        if (paymentType ==
                PaymentType.FREE) {

            /*
             * Fee is normalized to zero when saved.
             */
        }

        if (certificateEnabled &&
                !attendanceEnabled) {

            throw new RuntimeException(
                    "Attendance must be enabled to issue certificates");
        }
    }

    // ============================================================
    // EVENT SCOPE VALIDATION
    // ============================================================

    private void validateEventScope(
            Organizer organizer,
            EventScope scope) {

        if (scope == null) {

            throw new RuntimeException(
                    "Event scope is required");
        }

        /*
         * A Department-scoped event requires the Organizer's
         * Organization to belong to a Department.
         */
        if (scope == EventScope.DEPARTMENT) {

            if (organizer.getOrganization() == null) {

                throw new RuntimeException(
                        "Organizer is not associated with an organization");
            }

            if (organizer.getOrganization().getDepartment() == null) {

                throw new RuntimeException(
                        "Department-scoped events are not allowed for a college-wide organization");
            }
        }

        /*
         * ORGANIZATION scope is valid for both:
         *
         * 1. Department-specific organizations
         * 2. College-wide organizations
         */
        if (scope == EventScope.ORGANIZATION) {

            if (organizer.getOrganization() == null) {

                throw new RuntimeException(
                        "Organizer is not associated with an organization");
            }
        }
    }

    // ============================================================
    // OWNERSHIP
    // ============================================================

    private Event getOwnedEvent(
            Long userId,
            Long eventId) {

        Organizer organizer =
                getOrganizerByUserId(userId);

        Event event =
                eventRepository
                        .findByIdAndDeletedFalse(
                                eventId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Event not found"));

        if (!event.getOrganizer()
                .getId()
                .equals(organizer.getId())) {

            throw new RuntimeException(
                    "You are not allowed to manage this event");
        }

        return event;
    }

    // ============================================================
    // GET ORGANIZER
    // ============================================================

    private Organizer getOrganizerByUserId(
            Long userId) {

        Organizer organizer =
                organizerRepository
                        .findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer account not found"));

        Long organizationId =
                organizer.getOrganization().getId();

        /*
         * Explicitly reload the Organization together with
         * its Department relationship.
         */
        organizer.setOrganization(
                organizationRepository
                        .findByIdWithDepartment(organizationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization account not found")));

        return organizer;
    }

    // ============================================================
    // RESPONSE MAPPING
    // ============================================================

    private EventResponse toResponse(
            Event event) {

        Organizer organizer =
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