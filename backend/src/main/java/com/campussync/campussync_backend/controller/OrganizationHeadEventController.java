
package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.dto.RejectEventRequest;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.OrganizationHeadEventApprovalService;
import com.campussync.campussync_backend.service.OrganizationHeadEventService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/organization-head/events")
public class OrganizationHeadEventController {

    private final OrganizationHeadEventApprovalService approvalService;
    private final OrganizationHeadEventService eventService;

    public OrganizationHeadEventController(
            OrganizationHeadEventApprovalService approvalService,
            OrganizationHeadEventService eventService) {

        this.approvalService = approvalService;
        this.eventService = eventService;
    }

    // ============================================================
    // GET ALL ORGANIZATION EVENTS
    // ============================================================

    @GetMapping
    public ResponseEntity<List<EventResponse>> getOrganizationEvents(
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                eventService.getOrganizationEvents(
                        user.getId()));
    }

    // ============================================================
    // GET PENDING EVENTS
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
                    "Organization Head authentication required");
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

