package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.EventRegistrationResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.EventRegistrationService;

@RestController
@RequestMapping("/api")
public class EventRegistrationController {

    private final EventRegistrationService registrationService;

    public EventRegistrationController(
            EventRegistrationService registrationService) {

        this.registrationService =
                registrationService;
    }

    // ============================================================
    // STUDENT REGISTER
    // POST /api/student/events/{eventId}/register
    // ============================================================

    @PostMapping(
            "/student/events/{eventId}/register")
    public ResponseEntity<EventRegistrationResponse>
    register(
            @PathVariable Long eventId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                registrationService.register(
                        user.getId(),
                        eventId));
    }

    // ============================================================
    // ORGANIZER: SEE REGISTERED STUDENTS
    // GET /api/organizer/events/{eventId}/registrations
    // ============================================================

    @GetMapping(
            "/organizer/events/{eventId}/registrations")
    public ResponseEntity<
            List<EventRegistrationResponse>>
    getRegisteredStudents(
            @PathVariable Long eventId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                registrationService
                        .getRegisteredStudents(
                                user.getId(),
                                eventId));
    }

    // ============================================================
    // AUTHENTICATED USER
    // ============================================================

    private User getAuthenticatedUser(
            Authentication authentication) {

        if (authentication == null ||
                !authentication.isAuthenticated()) {

            throw new RuntimeException(
                    "Authentication required");
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