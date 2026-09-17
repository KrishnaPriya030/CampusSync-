package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PathVariable;
import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.StudentEventService;

@RestController
@RequestMapping("/api/student/events")
public class StudentEventController {

    private final StudentEventService eventService;

    public StudentEventController(
            StudentEventService eventService) {

        this.eventService = eventService;
    }

    @GetMapping
    public ResponseEntity<List<EventResponse>> getPublishedEvents(
            Authentication authentication) {

        getAuthenticatedStudent(authentication);

        return ResponseEntity.ok(
                eventService.getPublishedEvents()
        );
    }
    @GetMapping("/{id}")
public ResponseEntity<EventResponse> getPublishedEvent(
        @PathVariable Long id,
        Authentication authentication) {

    getAuthenticatedStudent(authentication);

    return ResponseEntity.ok(
            eventService.getPublishedEvent(id)
    );
}

    private User getAuthenticatedStudent(
            Authentication authentication) {

        if (authentication == null
                || !authentication.isAuthenticated()) {

            throw new RuntimeException(
                    "Student authentication required"
            );
        }

        Object principal =
                authentication.getPrincipal();

        if (!(principal instanceof User)) {

            throw new RuntimeException(
                    "Invalid authenticated user"
            );
        }

        User user = (User) principal;

        if (user.getRole() !=
                com.campussync.campussync_backend.enums.Role.STUDENT) {

            throw new RuntimeException(
                    "Student access required"
            );
        }

        return user;
    }
}