package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.CreateEventRequest;
import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.dto.UpdateEventRequest;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.OrganizerEventService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/organizer/events")
public class OrganizerEventController {

    private final OrganizerEventService eventService;

    public OrganizerEventController(
            OrganizerEventService eventService) {

        this.eventService = eventService;
    }

    // ============================================================
    // CREATE EVENT
    // POST /api/organizer/events
    // ============================================================

    @PostMapping
    public ResponseEntity<EventResponse> createEvent(
            @Valid @RequestBody CreateEventRequest request,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        EventResponse response =
                eventService.create(
                        user.getId(),
                        request);

        return ResponseEntity.ok(response);
    }

    // ============================================================
    // GET MY EVENTS
    // GET /api/organizer/events
    // ============================================================

    @GetMapping
    public ResponseEntity<List<EventResponse>> getMyEvents(
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.getMyEvents(user.getId())
        );
    }

    // ============================================================
    // GET EVENT BY ID
    // GET /api/organizer/events/{id}
    // ============================================================

    @GetMapping("/{id}")
    public ResponseEntity<EventResponse> getEventById(
            @PathVariable Long id,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.getById(
                        user.getId(),
                        id)
        );
    }

    // ============================================================
    // UPDATE EVENT
    // PUT /api/organizer/events/{id}
    // ============================================================

    @PutMapping("/{id}")
    public ResponseEntity<EventResponse> updateEvent(
            @PathVariable Long id,
            @Valid @RequestBody UpdateEventRequest request,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.update(
                        user.getId(),
                        id,
                        request)
        );
    }

    // ============================================================
    // DELETE EVENT
    // DELETE /api/organizer/events/{id}
    // ============================================================

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvent(
            @PathVariable Long id,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        eventService.delete(
                user.getId(),
                id);

        return ResponseEntity.noContent().build();
    }

    // ============================================================
    // PUBLISH EVENT
    // PUT /api/organizer/events/{id}/publish
    // ============================================================

    @PutMapping("/{id}/publish")
    public ResponseEntity<EventResponse> publishEvent(
            @PathVariable Long id,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.publish(
                        user.getId(),
                        id)
        );
    }

    // ============================================================
    // AUTHENTICATED USER
    // ============================================================

    private User getAuthenticatedUser(
            Authentication authentication) {

        if (authentication == null ||
                !authentication.isAuthenticated()) {

            throw new RuntimeException(
                    "Organizer authentication required");
        }

        Object principal =
                authentication.getPrincipal();

        if (!(principal instanceof User)) {

            throw new RuntimeException(
                    "Invalid authenticated user");
        }

        return (User) principal;
    }
}