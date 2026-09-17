package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.DepartmentRequest;
import com.campussync.campussync_backend.dto.DepartmentResponse;
import com.campussync.campussync_backend.service.DepartmentService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/departments")
public class AdminDepartmentController {

    private final DepartmentService departmentService;

    public AdminDepartmentController(
            DepartmentService departmentService) {

        this.departmentService = departmentService;
    }

    @GetMapping
    public ResponseEntity<List<DepartmentResponse>> getAll() {

        return ResponseEntity.ok(
                departmentService.getAllDepartments());
    }

    @PostMapping
    public ResponseEntity<DepartmentResponse> create(
            @Valid @RequestBody DepartmentRequest request) {

        return ResponseEntity.ok(
                departmentService.createDepartment(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DepartmentResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody DepartmentRequest request) {

        return ResponseEntity.ok(
                departmentService.updateDepartment(
                        id, request));
    }

    @PutMapping("/{id}/activate")
    public ResponseEntity<DepartmentResponse> activate(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                departmentService.activateDepartment(id));
    }

    @PutMapping("/{id}/deactivate")
    public ResponseEntity<DepartmentResponse> deactivate(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                departmentService.deactivateDepartment(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id) {

        departmentService.deleteDepartment(id);

        return ResponseEntity.noContent().build();
    }
}