package com.campussync.campussync_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.ActivateOrganizerRequest;
import com.campussync.campussync_backend.service.OrganizerManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth/organizer")
public class OrganizerActivationController {

    private final OrganizerManagementService organizerService;

    public OrganizerActivationController(
            OrganizerManagementService organizerService) {

        this.organizerService = organizerService;
    }

    @PostMapping("/activate")
    public ResponseEntity<String> activate(
            @Valid @RequestBody ActivateOrganizerRequest request) {

        organizerService.activateAccount(
                request.getToken(),
                request.getPassword(),
                request.getConfirmPassword());

        return ResponseEntity.ok(
                "Organizer account activated successfully");
    }
}