package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.campussync.campussync_backend.dto.BranchResponse;
import com.campussync.campussync_backend.dto.DepartmentResponse;
import com.campussync.campussync_backend.entity.Branch;
import com.campussync.campussync_backend.entity.Department;
import com.campussync.campussync_backend.repository.BranchRepository;
import com.campussync.campussync_backend.repository.DepartmentRepository;

@RestController
@RequestMapping("/api/admin/academic")
public class AcademicController {

    private final DepartmentRepository departmentRepository;
    private final BranchRepository branchRepository;

    public AcademicController(
            DepartmentRepository departmentRepository,
            BranchRepository branchRepository) {

        this.departmentRepository = departmentRepository;
        this.branchRepository = branchRepository;
    }

    @GetMapping("/departments")
    public ResponseEntity<List<DepartmentResponse>> getDepartments() {

        List<DepartmentResponse> departments =
                departmentRepository.findAll()
                        .stream()
                        .map(department -> new DepartmentResponse(
                                department.getId(),
                                department.getName(),
                                department.getCode(),
                                department.getActive()
                        ))
                        .toList();

        return ResponseEntity.ok(departments);
    }

    @GetMapping("/branches")
    public ResponseEntity<List<BranchResponse>> getBranches(
            @RequestParam Long departmentId) {

        Department department = departmentRepository
                .findById(departmentId)
                .orElseThrow(() ->
                        new RuntimeException("Department not found"));

        List<BranchResponse> branches =
                branchRepository.findAll()
                        .stream()
                        .filter(branch ->
                                branch.getDepartment()
                                        .getId()
                                        .equals(department.getId()))
                        .map(branch -> new BranchResponse(
                                branch.getId(),
                                branch.getName(),
                                branch.getCode(),
                                branch.getActive()
                        ))
                        .toList();

        return ResponseEntity.ok(branches);
    }
}