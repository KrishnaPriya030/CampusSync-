package com.campussync.campussync_backend.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.dto.DepartmentRequest;
import com.campussync.campussync_backend.dto.DepartmentResponse;
import com.campussync.campussync_backend.entity.Department;
import com.campussync.campussync_backend.repository.DepartmentRepository;

@Service
public class DepartmentService {

    private final DepartmentRepository departmentRepository;

    public DepartmentService(
            DepartmentRepository departmentRepository) {

        this.departmentRepository = departmentRepository;
    }

    public List<DepartmentResponse> getAllDepartments() {

        return departmentRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public DepartmentResponse createDepartment(
            DepartmentRequest request) {

        if (departmentRepository
                .findByCode(request.code())
                .isPresent()) {

            throw new RuntimeException(
                    "Department code already exists");
        }

        Department department = new Department();

        department.setName(request.name());
        department.setCode(request.code());
        department.setActive(true);

        Department saved =
                departmentRepository.save(department);

        return toResponse(saved);
    }

    public DepartmentResponse updateDepartment(
            Long id,
            DepartmentRequest request) {

        Department department =
                departmentRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Department not found"));

        if (!department.getCode()
                .equals(request.code())
                && departmentRepository
                        .findByCode(request.code())
                        .isPresent()) {

            throw new RuntimeException(
                    "Department code already exists");
        }

        department.setName(request.name());
        department.setCode(request.code());

        Department updated =
                departmentRepository.save(department);

        return toResponse(updated);
    }

    public DepartmentResponse activateDepartment(Long id) {

        Department department =
                departmentRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Department not found"));

        department.setActive(true);

        return toResponse(
                departmentRepository.save(department));
    }

    public DepartmentResponse deactivateDepartment(Long id) {

        Department department =
                departmentRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Department not found"));

        department.setActive(false);

        return toResponse(
                departmentRepository.save(department));
    }

    public void deleteDepartment(Long id) {

        Department department =
                departmentRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Department not found"));

        departmentRepository.delete(department);
    }

    private DepartmentResponse toResponse(
            Department department) {

        return new DepartmentResponse(
                department.getId(),
                department.getName(),
                department.getCode(),
                department.getActive()
        );
    }
}