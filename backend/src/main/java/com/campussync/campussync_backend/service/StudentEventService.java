package com.campussync.campussync_backend.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.repository.EventRepository;

@Service
public class StudentEventService {

    private final EventRepository eventRepository;

    public StudentEventService(
            EventRepository eventRepository) {

        this.eventRepository = eventRepository;
    }

    public List<EventResponse> getPublishedEvents() {

        return eventRepository
                .findByStatusAndDeletedFalseOrderByStartDateTimeAsc(
                        EventStatus.PUBLISHED)
                .stream()
                .map(this::toResponse)
                .toList();
    }
    public EventResponse getPublishedEvent(Long eventId) {

    Event event = eventRepository
            .findByIdAndStatusAndDeletedFalse(
                    eventId,
                    EventStatus.PUBLISHED)
            .orElseThrow(() ->
                    new RuntimeException(
                            "Published event not found"));

    return toResponse(event);
}

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