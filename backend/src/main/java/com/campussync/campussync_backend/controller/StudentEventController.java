
package com.campussync.campussync_backend.controller;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.EventScope;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.service.StudentEventService;

@RestController
@RequestMapping("/api/student/events")
public class StudentEventController {

    private final StudentEventService eventService;

    public StudentEventController(StudentEventService eventService) {
        this.eventService = eventService;
    }

    // GET ALL PUBLISHED EVENTS
    @GetMapping
    public ResponseEntity<List<EventResponse>> getPublishedEvents(
            Authentication authentication) {

        getAuthenticatedStudent(authentication);

        return ResponseEntity.ok(
                eventService.getPublishedEvents()
        );
    }

    // SEARCH AND FILTER PUBLISHED EVENTS
    @GetMapping("/search")
    public ResponseEntity<List<EventResponse>> searchEvents(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) Long organizationId,
            @RequestParam(required = false) EventScope scope,
            @RequestParam(required = false) PaymentType paymentType,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
            LocalDateTime startDate,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
            LocalDateTime endDate,
            Authentication authentication) {

        getAuthenticatedStudent(authentication);

        return ResponseEntity.ok(
                eventService.searchEvents(
                        keyword,
                        departmentId,
                        organizationId,
                        scope,
                        paymentType,
                        startDate,
                        endDate
                )
        );
    }

    // GET A SINGLE PUBLISHED EVENT
    @GetMapping("/{id}")
    public ResponseEntity<EventResponse> getPublishedEvent(
            @PathVariable Long id,
            Authentication authentication) {

        getAuthenticatedStudent(authentication);

        return ResponseEntity.ok(
                eventService.getPublishedEvent(id)
        );
    }

    // VERIFY THAT THE REQUEST IS FROM AN AUTHENTICATED STUDENT
    private User getAuthenticatedStudent(Authentication authentication) {

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Student authentication required"
            );
        }

        Object principal = authentication.getPrincipal();

        if (!(principal instanceof User)) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid authenticated user"
            );
        }

        User user = (User) principal;

        if (user.getRole() != Role.STUDENT) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Student access required"
            );
        }

        return user;
    }
}
