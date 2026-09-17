package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.dto.RejectEventRequest;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.DepartmentHeadEventApprovalService;
import com.campussync.campussync_backend.service.DepartmentHeadEventService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/department-head/events")
public class DepartmentHeadEventController {

    private final DepartmentHeadEventApprovalService approvalService;
    private final DepartmentHeadEventService eventService;

    public DepartmentHeadEventController(
            DepartmentHeadEventApprovalService approvalService,
            DepartmentHeadEventService eventService) {

        this.approvalService = approvalService;
        this.eventService = eventService;
    }

    // ============================================================
    // GET ALL DEPARTMENT EVENTS
    // ============================================================

    @GetMapping
    public ResponseEntity<List<EventResponse>> getDepartmentEvents(
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.getDepartmentEvents(
                        user.getId()));
    }

    // ============================================================
    // GET PENDING DEPARTMENT EVENTS
    // ============================================================

    @GetMapping("/pending")
    public ResponseEntity<List<EventResponse>> getPendingEvents(
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.getPendingEvents(
                        user.getId()));
    }

    // ============================================================
    // APPROVE EVENT
    // ============================================================

    @PutMapping("/{id}/approve")
    public ResponseEntity<EventResponse> approveEvent(
            @PathVariable Long id,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                approvalService.approve(
                        user.getId(),
                        id));
    }

    // ============================================================
    // REJECT EVENT
    // ============================================================

    @PutMapping("/{id}/reject")
    public ResponseEntity<EventResponse> rejectEvent(
            @PathVariable Long id,
            @Valid @RequestBody RejectEventRequest request,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                approvalService.reject(
                        user.getId(),
                        id,
                        request.reason()));
    }

    // ============================================================
    // AUTHENTICATED USER
    // ============================================================

    private User getAuthenticatedUser(
            Authentication authentication) {

        if (authentication == null ||
                !authentication.isAuthenticated()) {

            throw new RuntimeException(
                    "Department Head authentication required");
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