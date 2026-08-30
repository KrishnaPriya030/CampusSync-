package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.CreateOrganizerRequest;
import com.campussync.campussync_backend.dto.CreateOrganizerResponse;
import com.campussync.campussync_backend.dto.OrganizerResponse;
import com.campussync.campussync_backend.service.OrganizerManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/organizers")
public class AdminOrganizerController {

    private final OrganizerManagementService organizerService;

    public AdminOrganizerController(
            OrganizerManagementService organizerService) {

        this.organizerService = organizerService;
    }

    @PostMapping
    public ResponseEntity<CreateOrganizerResponse> create(
            @Valid @RequestBody CreateOrganizerRequest request) {

        return ResponseEntity.ok(
                organizerService.create(request));
    }

    @GetMapping
    public ResponseEntity<List<OrganizerResponse>> getAll() {

        return ResponseEntity.ok(
                organizerService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrganizerResponse> getById(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizerService.getById(id));
    }

    @PutMapping("/{id}/activate")
    public ResponseEntity<OrganizerResponse> activate(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizerService.activate(id));
    }

    @PutMapping("/{id}/block")
    public ResponseEntity<OrganizerResponse> block(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizerService.block(id));
    }
}