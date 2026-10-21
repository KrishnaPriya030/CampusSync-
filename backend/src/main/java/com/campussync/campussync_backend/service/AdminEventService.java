package com.campussync.campussync_backend.service;

import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.Organizer;
import com.campussync.campussync_backend.repository.EventRepository;

@Service
public class AdminEventService {
    private final EventRepository eventRepository;

    public AdminEventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    @Transactional(readOnly = true)
    public List<EventResponse> getAllEvents() {
        return eventRepository.findByDeletedFalseOrderByCreatedAtDesc()
                .stream().map(this::toResponse).toList();
    }

    private EventResponse toResponse(Event event) {
        Organizer organizer = event.getOrganizer();
        return new EventResponse(
                event.getId(), organizer.getId(), organizer.getUser().getName(),
                organizer.getOrganization().getId(), organizer.getOrganization().getName(),
                event.getTitle(), event.getDescription(), event.getVenue(),
                event.getStartDateTime(), event.getEndDateTime(), event.getRegistrationDeadline(),
                event.getScope(), event.getCapacityType(), event.getCapacity(),
                event.getPaymentType(), event.getRegistrationFee(), event.getRefundPolicy(),
                event.isAttendanceEnabled(), event.isCertificateEnabled(), event.getStatus());
    }
}
