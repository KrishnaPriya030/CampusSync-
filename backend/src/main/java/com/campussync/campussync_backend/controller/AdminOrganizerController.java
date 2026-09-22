
package com.campussync.campussync_backend.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.campussync.campussync_backend.dto.AdminResetPasswordRequest;
import com.campussync.campussync_backend.dto.BulkStudentImportResponse;
import com.campussync.campussync_backend.dto.CreateOrganizerRequest;
import com.campussync.campussync_backend.dto.CreateOrganizerResponse;
import com.campussync.campussync_backend.dto.OrganizerResponse;
import com.campussync.campussync_backend.service.OrganizerImportService;
import com.campussync.campussync_backend.service.OrganizerManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/organizers")
public class AdminOrganizerController {

    private final OrganizerManagementService organizerService;
    private final OrganizerImportService organizerImportService;

    public AdminOrganizerController(
            OrganizerManagementService organizerService,
            OrganizerImportService organizerImportService) {

        this.organizerService = organizerService;
        this.organizerImportService = organizerImportService;
    }

    // ============================================================
    // CREATE ORGANIZER
    // ============================================================

    @PostMapping
    public ResponseEntity<CreateOrganizerResponse> create(
            @Valid @RequestBody CreateOrganizerRequest request) {

        return ResponseEntity.ok(
                organizerService.create(request)
        );
    }

    // ============================================================
    // IMPORT ORGANIZERS FROM EXCEL
    // ============================================================

    @PostMapping(
            value = "/import",
            consumes = "multipart/form-data"
    )
    public ResponseEntity<BulkStudentImportResponse> importOrganizers(
            @RequestParam("file") MultipartFile file) {

        return ResponseEntity.ok(
                organizerImportService.importOrganizers(file)
        );
    }

    // ============================================================
    // GET ALL ORGANIZERS
    // ============================================================

    @GetMapping
    public ResponseEntity<List<OrganizerResponse>> getAll() {

        return ResponseEntity.ok(
                organizerService.getAll()
        );
    }

    // ============================================================
    // GET ORGANIZER BY ID
    // ============================================================

    @GetMapping("/{id}")
    public ResponseEntity<OrganizerResponse> getById(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizerService.getById(id)
        );
    }

    // ============================================================
    // ACTIVATE ORGANIZER
    // ============================================================

    @PutMapping("/{id}/activate")
    public ResponseEntity<OrganizerResponse> activate(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizerService.activate(id)
        );
    }

    // ============================================================
    // BLOCK ORGANIZER
    // ============================================================

    @PutMapping("/{id}/block")
    public ResponseEntity<OrganizerResponse> block(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                organizerService.block(id)
        );
    }

    // ============================================================
    // ADMIN RESET ORGANIZER PASSWORD
    // ============================================================

    @PutMapping("/{id}/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(
            @PathVariable Long id,
            @Valid @RequestBody AdminResetPasswordRequest request) {

        if (!request.getNewPassword().equals(
                request.getConfirmPassword())) {

            throw new RuntimeException(
                    "Passwords do not match"
            );
        }

        organizerService.resetPassword(
                id,
                request.getNewPassword()
        );

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Organizer password reset successfully"
                )
        );
    }
}

