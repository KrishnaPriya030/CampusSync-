package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.OrganizationRequest;
import com.campussync.campussync_backend.dto.OrganizationResponse;
import com.campussync.campussync_backend.service.OrganizationService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/organizations")
public class AdminOrganizationController {

    private final OrganizationService organizationService;

    public AdminOrganizationController(
            OrganizationService organizationService) {

        this.organizationService = organizationService;
    }

    @PostMapping
    public ResponseEntity<OrganizationResponse> create(
            @Valid @RequestBody OrganizationRequest request) {

        return ResponseEntity.ok(
                organizationService.create(request));
    }

    @GetMapping
    public ResponseEntity<List<OrganizationResponse>> getAll() {

        return ResponseEntity.ok(
                organizationService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrganizationResponse> getById(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizationService.getById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OrganizationResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody OrganizationRequest request) {

        return ResponseEntity.ok(
                organizationService.update(id, request));
    }

    @PutMapping("/{id}/activate")
    public ResponseEntity<OrganizationResponse> activate(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizationService.activate(id));
    }

    @PutMapping("/{id}/deactivate")
    public ResponseEntity<OrganizationResponse> deactivate(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizationService.deactivate(id));
    }
}