package com.campussync.campussync_backend.controller;
import com.campussync.campussync_backend.dto.CreateDepartmentHeadResponse;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.CreateDepartmentHeadRequest;
import com.campussync.campussync_backend.dto.DepartmentHeadResponse;
import com.campussync.campussync_backend.service.DepartmentHeadManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/department-heads")
public class AdminDepartmentHeadController {

    private final DepartmentHeadManagementService service;

    public AdminDepartmentHeadController(
            DepartmentHeadManagementService service) {
        this.service = service;
    }

    @PostMapping
public ResponseEntity<CreateDepartmentHeadResponse> create(
        @Valid @RequestBody CreateDepartmentHeadRequest request) {

    return ResponseEntity.ok(service.create(request));
}

    @GetMapping
    public ResponseEntity<List<DepartmentHeadResponse>> getAll() {

        return ResponseEntity.ok(service.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<DepartmentHeadResponse> getById(
            @PathVariable Long id) {

        return ResponseEntity.ok(service.getById(id));
    }

    @PutMapping("/{id}/activate")
    public ResponseEntity<DepartmentHeadResponse> activate(
            @PathVariable Long id) {

        return ResponseEntity.ok(service.activate(id));
    }

    @PutMapping("/{id}/block")
    public ResponseEntity<DepartmentHeadResponse> block(
            @PathVariable Long id) {

        return ResponseEntity.ok(service.block(id));
    }
}