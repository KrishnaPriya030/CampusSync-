package com.campussync.campussync_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.CreateStudentRequest;
import com.campussync.campussync_backend.dto.CreateStudentResponse;
import com.campussync.campussync_backend.service.StudentManagementService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/admin/students")
public class AdminStudentController {

    private final StudentManagementService studentManagementService;

    public AdminStudentController(StudentManagementService studentManagementService) {
        this.studentManagementService = studentManagementService;
    }

    @PostMapping
    public ResponseEntity<CreateStudentResponse> createStudent(
            @Valid @RequestBody CreateStudentRequest request) {

        CreateStudentResponse response =
                studentManagementService.createStudent(request);

        return ResponseEntity.ok(response);
    }
}