package com.campussync.campussync_backend.controller;

import java.util.List;
import com.campussync.campussync_backend.dto.CreateOrganizationHeadResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.CreateOrganizationHeadRequest;
import com.campussync.campussync_backend.dto.OrganizationHeadResponse;
import com.campussync.campussync_backend.service.OrganizationHeadManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/organization-heads")
public class AdminOrganizationHeadController {

    private final OrganizationHeadManagementService service;

    public AdminOrganizationHeadController(
            OrganizationHeadManagementService service) {
        this.service = service;
    }

@PostMapping
public ResponseEntity<CreateOrganizationHeadResponse> create(
        @Valid @RequestBody CreateOrganizationHeadRequest request) {
    return ResponseEntity.ok(service.create(request));
}
    @GetMapping
    public ResponseEntity<List<OrganizationHeadResponse>> getAll() {

        return ResponseEntity.ok(service.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrganizationHeadResponse> getById(
            @PathVariable Long id) {

        return ResponseEntity.ok(service.getById(id));
    }

    @PutMapping("/{id}/activate")
    public ResponseEntity<OrganizationHeadResponse> activate(
            @PathVariable Long id) {

        return ResponseEntity.ok(service.activate(id));
    }

    @PutMapping("/{id}/block")
    public ResponseEntity<OrganizationHeadResponse> block(
            @PathVariable Long id) {

        return ResponseEntity.ok(service.block(id));
    }
}