package com.campussync.campussync_backend.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.OrganizationRequest;
import com.campussync.campussync_backend.dto.OrganizationResponse;
import com.campussync.campussync_backend.entity.Department;
import com.campussync.campussync_backend.entity.Organization;
import com.campussync.campussync_backend.repository.DepartmentRepository;
import com.campussync.campussync_backend.repository.OrganizationRepository;

@Service
public class OrganizationService {

    private final OrganizationRepository organizationRepository;
    private final DepartmentRepository departmentRepository;

    public OrganizationService(
            OrganizationRepository organizationRepository,
            DepartmentRepository departmentRepository) {

        this.organizationRepository = organizationRepository;
        this.departmentRepository = departmentRepository;
    }

    @Transactional
    public OrganizationResponse create(
            OrganizationRequest request) {

        if (organizationRepository.existsByCode(request.getCode())) {
            throw new RuntimeException(
                    "Organization code already exists");
        }

        Organization organization = new Organization();

        organization.setName(request.getName());
        organization.setCode(request.getCode());
        organization.setOrganizationType(
                request.getOrganizationType());
        organization.setDescription(
                request.getDescription());
        organization.setActive(true);

        if (request.getDepartmentId() != null) {

            Department department =
                    departmentRepository.findById(
                            request.getDepartmentId())
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Department not found"));

            organization.setDepartment(department);
        }

        Organization saved =
                organizationRepository.save(organization);

        return toResponse(saved);
    }

    public List<OrganizationResponse> getAll() {

        return organizationRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public OrganizationResponse getById(Long id) {

        Organization organization =
                organizationRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization not found"));

        return toResponse(organization);
    }

    @Transactional
    public OrganizationResponse update(
            Long id,
            OrganizationRequest request) {

        Organization organization =
                organizationRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization not found"));

        if (!organization.getCode()
                .equals(request.getCode())
                && organizationRepository
                        .existsByCode(request.getCode())) {

            throw new RuntimeException(
                    "Organization code already exists");
        }

        organization.setName(request.getName());
        organization.setCode(request.getCode());
        organization.setOrganizationType(
                request.getOrganizationType());
        organization.setDescription(
                request.getDescription());

        if (request.getDepartmentId() != null) {

            Department department =
                    departmentRepository.findById(
                            request.getDepartmentId())
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Department not found"));

            organization.setDepartment(department);

        } else {

            organization.setDepartment(null);
        }

        return toResponse(
                organizationRepository.save(organization));
    }

    @Transactional
    public OrganizationResponse activate(Long id) {

        Organization organization =
                organizationRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization not found"));

        organization.setActive(true);

        return toResponse(
                organizationRepository.save(organization));
    }

    @Transactional
    public OrganizationResponse deactivate(Long id) {

        Organization organization =
                organizationRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization not found"));

        organization.setActive(false);

        return toResponse(
                organizationRepository.save(organization));
    }

    private OrganizationResponse toResponse(
            Organization organization) {

        Department department =
                organization.getDepartment();

        return new OrganizationResponse(
                organization.getId(),
                organization.getName(),
                organization.getCode(),
                organization.getOrganizationType(),
                department != null
                        ? department.getId()
                        : null,
                department != null
                        ? department.getName()
                        : null,
                organization.getDescription(),
                organization.isActive()
        );
    }
}