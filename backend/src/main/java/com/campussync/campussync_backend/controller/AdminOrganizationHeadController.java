
package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.campussync.campussync_backend.dto.BulkStudentImportResponse;
import com.campussync.campussync_backend.dto.CreateOrganizationHeadRequest;
import com.campussync.campussync_backend.dto.CreateOrganizationHeadResponse;
import com.campussync.campussync_backend.dto.OrganizationHeadResponse;
import com.campussync.campussync_backend.service.OrganizationHeadImportService;
import com.campussync.campussync_backend.service.OrganizationHeadManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/organization-heads")
public class AdminOrganizationHeadController {

    private final OrganizationHeadManagementService organizationHeadService;
    private final OrganizationHeadImportService organizationHeadImportService;

    public AdminOrganizationHeadController(
            OrganizationHeadManagementService organizationHeadService,
            OrganizationHeadImportService organizationHeadImportService) {

        this.organizationHeadService = organizationHeadService;
        this.organizationHeadImportService =
                organizationHeadImportService;
    }

    // ============================================================
    // CREATE ORGANIZATION HEAD
    // ============================================================

    @PostMapping
    public ResponseEntity<CreateOrganizationHeadResponse> create(
            @Valid @RequestBody CreateOrganizationHeadRequest request) {

        return ResponseEntity.ok(
                organizationHeadService.create(request));
    }

    // ============================================================
    // IMPORT ORGANIZATION HEADS FROM EXCEL
    // ============================================================

    @PostMapping(
            value = "/import",
            consumes = "multipart/form-data"
    )
    public ResponseEntity<BulkStudentImportResponse> importOrganizationHeads(
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        BulkStudentImportResponse response =
                organizationHeadImportService
                        .importOrganizationHeads(file);

        return ResponseEntity.ok(response);
    }

    // ============================================================
    // GET ALL ORGANIZATION HEADS
    // ============================================================

    @GetMapping
    public ResponseEntity<List<OrganizationHeadResponse>> getAll() {

        return ResponseEntity.ok(
                organizationHeadService.getAll());
    }

    // ============================================================
    // GET ORGANIZATION HEAD BY ID
    // ============================================================

    @GetMapping("/{id}")
    public ResponseEntity<OrganizationHeadResponse> getById(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizationHeadService.getById(id));
    }

    // ============================================================
    // ACTIVATE
    // ============================================================

    @PutMapping("/{id}/activate")
    public ResponseEntity<OrganizationHeadResponse> activate(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizationHeadService.activate(id));
    }

    // ============================================================
    // BLOCK
    // ============================================================

    @PutMapping("/{id}/block")
    public ResponseEntity<OrganizationHeadResponse> block(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizationHeadService.block(id));
    }
}

