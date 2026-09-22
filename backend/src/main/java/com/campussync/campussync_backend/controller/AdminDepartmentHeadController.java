
package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.campussync.campussync_backend.dto.BulkStudentImportResponse;
import com.campussync.campussync_backend.dto.CreateDepartmentHeadRequest;
import com.campussync.campussync_backend.dto.CreateDepartmentHeadResponse;
import com.campussync.campussync_backend.dto.DepartmentHeadResponse;
import com.campussync.campussync_backend.service.DepartmentHeadImportService;
import com.campussync.campussync_backend.service.DepartmentHeadManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/department-heads")
public class AdminDepartmentHeadController {

    private final DepartmentHeadManagementService departmentHeadService;
    private final DepartmentHeadImportService departmentHeadImportService;

    public AdminDepartmentHeadController(
            DepartmentHeadManagementService departmentHeadService,
            DepartmentHeadImportService departmentHeadImportService) {

        this.departmentHeadService = departmentHeadService;
        this.departmentHeadImportService = departmentHeadImportService;
    }

    // ============================================================
    // CREATE DEPARTMENT HEAD
    // ============================================================

    @PostMapping
    public ResponseEntity<CreateDepartmentHeadResponse> create(
            @Valid @RequestBody CreateDepartmentHeadRequest request) {

        return ResponseEntity.ok(
                departmentHeadService.create(request));
    }

    // ============================================================
    // IMPORT DEPARTMENT HEADS FROM EXCEL
    // ============================================================

    @PostMapping(
            value = "/import",
            consumes = "multipart/form-data"
    )
    public ResponseEntity<BulkStudentImportResponse> importDepartmentHeads(
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        BulkStudentImportResponse response =
                departmentHeadImportService
                        .importDepartmentHeads(file);

        return ResponseEntity.ok(response);
    }

    // ============================================================
    // GET ALL
    // ============================================================

    @GetMapping
    public ResponseEntity<List<DepartmentHeadResponse>> getAll() {

        return ResponseEntity.ok(
                departmentHeadService.getAll());
    }

    // ============================================================
    // GET BY ID
    // ============================================================

    @GetMapping("/{id}")
    public ResponseEntity<DepartmentHeadResponse> getById(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                departmentHeadService.getById(id));
    }

    // ============================================================
    // ACTIVATE
    // ============================================================

    @PutMapping("/{id}/activate")
    public ResponseEntity<DepartmentHeadResponse> activate(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                departmentHeadService.activate(id));
    }

    // ============================================================
    // BLOCK
    // ============================================================

    @PutMapping("/{id}/block")
    public ResponseEntity<DepartmentHeadResponse> block(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                departmentHeadService.block(id));
    }
}

