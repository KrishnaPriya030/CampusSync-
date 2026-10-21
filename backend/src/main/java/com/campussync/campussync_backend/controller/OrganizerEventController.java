
package com.campussync.campussync_backend.controller;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.campussync.campussync_backend.dto.CreateEventRequest;
import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.dto.OrganizerAnalyticsResponse;
import com.campussync.campussync_backend.dto.UpdateEventRequest;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.OrganizerAnalyticsService;
import com.campussync.campussync_backend.service.OrganizerEventService;

@RestController
@RequestMapping("/api/organizer/events")
public class OrganizerEventController {

    private final OrganizerEventService eventService;
    private final OrganizerAnalyticsService analyticsService;

    public OrganizerEventController(
            OrganizerEventService eventService,
            OrganizerAnalyticsService analyticsService) {

        this.eventService = eventService;
        this.analyticsService = analyticsService;
    }

    // ============================================================
    // CREATE EVENT
    // ============================================================

    @PostMapping
    public ResponseEntity<EventResponse> createEvent(
            @Valid @RequestBody CreateEventRequest request,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        EventResponse response = eventService.create(
                user.getId(),
                request);

        return ResponseEntity.ok(response);
    }

    // ============================================================
    // GET MY EVENTS
    // ============================================================

    @GetMapping
    public ResponseEntity<List<EventResponse>> getMyEvents(
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.getMyEvents(user.getId()));
    }

    // ============================================================
    // GET ORGANIZER ANALYTICS
    // ============================================================

    @GetMapping("/analytics")
    public ResponseEntity<OrganizerAnalyticsResponse> getAnalytics(
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                analyticsService.getAnalytics(user.getId()));
    }

    // ============================================================
    // GET EVENT BY ID
    // ============================================================

    @GetMapping("/{id}")
    public ResponseEntity<EventResponse> getEventById(
            @PathVariable Long id,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.getById(
                        user.getId(),
                        id));
    }

    // ============================================================
    // UPDATE EVENT
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
                        request));
    }

    // ============================================================
    // SUBMIT FOR APPROVAL
    // ============================================================

    @PutMapping("/{id}/submit")
    public ResponseEntity<EventResponse> submitForApproval(
            @PathVariable Long id,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.submitForApproval(
                        user.getId(),
                        id));
    }

    // ============================================================
    // DELETE EVENT
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
    // CANCEL EVENT
    // ============================================================

    @PutMapping("/{id}/cancel")
    public ResponseEntity<EventResponse> cancelEvent(
            @PathVariable Long id,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.cancel(
                        user.getId(),
                        id));
    }

    // ============================================================
    // PUBLISH EVENT
    // ============================================================

    @PutMapping("/{id}/publish")
    public ResponseEntity<EventResponse> publishEvent(
            @PathVariable Long id,
            Authentication authentication) {

        User user = getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.publish(
                        user.getId(),
                        id));
    }

    // ============================================================
    // AUTHENTICATED USER
    // ============================================================

    private User getAuthenticatedUser(
            Authentication authentication) {

        if (authentication == null
                || !authentication.isAuthenticated()) {

            throw new RuntimeException(
                    "Organizer authentication required");
        }

        Object principal = authentication.getPrincipal();

        if (!(principal instanceof User)) {
            throw new RuntimeException(
                    "Invalid authenticated user");
        }

        return (User) principal;
    }
}
