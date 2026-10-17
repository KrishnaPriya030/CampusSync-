
package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.enums.EventScope;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.repository.EventRepository;

@Service
public class StudentEventService {

    private final EventRepository eventRepository;

    public StudentEventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    // GET ALL PUBLISHED EVENTS
    public List<EventResponse> getPublishedEvents() {

        return eventRepository
                .findByStatusAndDeletedFalseOrderByStartDateTimeAsc(
                        EventStatus.PUBLISHED
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // SEARCH AND FILTER PUBLISHED EVENTS
    public List<EventResponse> searchEvents(
            String keyword,
            Long departmentId,
            Long organizationId,
            EventScope scope,
            PaymentType paymentType,
            LocalDateTime startDate,
            LocalDateTime endDate) {

        if (keyword != null && keyword.isBlank()) {
            keyword = null;
        }

        if (startDate != null && endDate != null
                && startDate.isAfter(endDate)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Start date must not be after end date"
            );
        }

        return eventRepository
                .searchPublishedEvents(
                        EventStatus.PUBLISHED,
                        keyword,
                        departmentId,
                        organizationId,
                        scope,
                        paymentType,
                        startDate,
                        endDate
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // GET A SINGLE PUBLISHED EVENT
    public EventResponse getPublishedEvent(Long eventId) {

        if (eventId == null || eventId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid event ID"
            );
        }

        Event event = eventRepository
                .findByIdAndStatusAndDeletedFalse(
                        eventId,
                        EventStatus.PUBLISHED
                )
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Published event not found"
                        )
                );

        return toResponse(event);
    }

    // MAP EVENT ENTITY TO STUDENT RESPONSE
    private EventResponse toResponse(Event event) {

        if (event == null
                || event.getOrganizer() == null
                || event.getOrganizer().getUser() == null
                || event.getOrganizer().getOrganization() == null) {

            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Event data is incomplete"
            );
        }

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