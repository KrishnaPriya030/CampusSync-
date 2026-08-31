package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.CreateEventRequest;
import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.dto.UpdateEventRequest;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.Organizer;
import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.OrganizerRepository;

@Service
public class OrganizerEventService {

    private final EventRepository eventRepository;
    private final OrganizerRepository organizerRepository;

    public OrganizerEventService(
            EventRepository eventRepository,
            OrganizerRepository organizerRepository) {

        this.eventRepository = eventRepository;
        this.organizerRepository = organizerRepository;
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

        Event event = new Event();

        event.setOrganizer(organizer);
        event.setTitle(request.title());
        event.setDescription(request.description());
        event.setVenue(request.venue());
        event.setStartDateTime(request.startDateTime());
        event.setEndDateTime(request.endDateTime());
        event.setRegistrationDeadline(
                request.registrationDeadline());

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

        event.setStatus(EventStatus.DRAFT);
        event.setDeleted(false);
        event.setCreatedAt(LocalDateTime.now());
        event.setUpdatedAt(LocalDateTime.now());

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

        event.setTitle(request.title());
        event.setDescription(request.description());
        event.setVenue(request.venue());
        event.setStartDateTime(
                request.startDateTime());
        event.setEndDateTime(
                request.endDateTime());
        event.setRegistrationDeadline(
                request.registrationDeadline());

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

        event.setUpdatedAt(LocalDateTime.now());

        return toResponse(
                eventRepository.save(event));
    }

    // ============================================================
    // DELETE
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
        event.setUpdatedAt(LocalDateTime.now());

        eventRepository.save(event);
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

        if (event.getStatus() != EventStatus.DRAFT) {
            throw new RuntimeException(
                    "Only draft events can be published");
        }

        if (event.getRegistrationDeadline()
                .isAfter(event.getStartDateTime())) {

            throw new RuntimeException(
                    "Registration deadline must be before event start");
        }

        event.setStatus(
                EventStatus.PUBLISHED);

        event.setUpdatedAt(
                LocalDateTime.now());

        return toResponse(
                eventRepository.save(event));
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
                    "Event end time must be after start time");
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

    private Organizer getOrganizerByUserId(
            Long userId) {

        return organizerRepository
                .findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Organizer account not found"));
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