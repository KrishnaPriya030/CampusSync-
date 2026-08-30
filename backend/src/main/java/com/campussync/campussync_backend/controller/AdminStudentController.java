package com.campussync.campussync_backend.controller;
import java.util.List;

import com.campussync.campussync_backend.dto.StudentListResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.multipart.MultipartFile;
import com.campussync.campussync_backend.dto.UpdateStudentRequest;


import com.campussync.campussync_backend.dto.BulkStudentImportResponse;
import com.campussync.campussync_backend.dto.CreateStudentRequest;
import com.campussync.campussync_backend.dto.CreateStudentResponse;
import com.campussync.campussync_backend.service.StudentImportService;
import com.campussync.campussync_backend.service.StudentManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/students")
public class AdminStudentController {

    private final StudentManagementService studentManagementService;
    private final StudentImportService studentImportService;

    public AdminStudentController(
            StudentManagementService studentManagementService,
            StudentImportService studentImportService) {

        this.studentManagementService = studentManagementService;
        this.studentImportService = studentImportService;
    }

    // Optional: Create one student manually
    @PostMapping
    public ResponseEntity<CreateStudentResponse> createStudent(
            @Valid @RequestBody CreateStudentRequest request) {

        CreateStudentResponse response =
                studentManagementService.createStudent(request);

        return ResponseEntity.ok(response);
    }

    // Main method: Bulk student import using Excel
    @PostMapping(
            value = "/import",
            consumes = "multipart/form-data"
    )
    public ResponseEntity<BulkStudentImportResponse> importStudents(
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        BulkStudentImportResponse response =
                studentImportService.importStudents(file);

        return ResponseEntity.ok(response);
    }
    @GetMapping
public ResponseEntity<List<StudentListResponse>> getAllStudents() {

    return ResponseEntity.ok(
            studentManagementService.getAllStudents()
    );
}
@GetMapping("/{id}")
public ResponseEntity<StudentListResponse> getStudentById(
        @PathVariable Long id) {

    return ResponseEntity.ok(
            studentManagementService.getStudentById(id)
    );
}
@PutMapping("/{id}")
public ResponseEntity<StudentListResponse> updateStudent(
        @PathVariable Long id,
        @Valid @RequestBody UpdateStudentRequest request) {

    return ResponseEntity.ok(
            studentManagementService.updateStudent(id, request)
    );
}
@PutMapping("/{id}/deactivate")
public ResponseEntity<StudentListResponse> deactivateStudent(
        @PathVariable Long id) {

    return ResponseEntity.ok(
            studentManagementService.deactivateStudent(id)
    );
}

@PutMapping("/{id}/activate")
public ResponseEntity<StudentListResponse> activateStudent(
        @PathVariable Long id) {

    return ResponseEntity.ok(
            studentManagementService.activateStudent(id)
    );
}


    
}