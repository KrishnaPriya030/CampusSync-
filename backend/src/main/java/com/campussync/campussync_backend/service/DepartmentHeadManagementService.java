
package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.CreateDepartmentHeadRequest;
import com.campussync.campussync_backend.dto.CreateDepartmentHeadResponse;
import com.campussync.campussync_backend.dto.DepartmentHeadResponse;
import com.campussync.campussync_backend.entity.Department;
import com.campussync.campussync_backend.entity.DepartmentHead;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.repository.DepartmentHeadRepository;
import com.campussync.campussync_backend.repository.DepartmentRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class DepartmentHeadManagementService {

    private final UserRepository userRepository;
    private final DepartmentHeadRepository departmentHeadRepository;
    private final DepartmentRepository departmentRepository;
    private final PasswordEncoder passwordEncoder;
    private final OrganizerActivationService activationService;

    @Value("${campussync.activation-url}")
    private String activationUrl;

    public DepartmentHeadManagementService(
            UserRepository userRepository,
            DepartmentHeadRepository departmentHeadRepository,
            DepartmentRepository departmentRepository,
            PasswordEncoder passwordEncoder,
            OrganizerActivationService activationService) {

        this.userRepository = userRepository;
        this.departmentHeadRepository = departmentHeadRepository;
        this.departmentRepository = departmentRepository;
        this.passwordEncoder = passwordEncoder;
        this.activationService = activationService;
    }

    // ============================================================
    // CREATE DEPARTMENT HEAD
    // ============================================================

    @Transactional
    public CreateDepartmentHeadResponse create(
            CreateDepartmentHeadRequest request) {

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists");
        }

        Department department =
                departmentRepository.findById(
                        request.getDepartmentId())
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Department not found"));

        if (department.getActive() == null ||
                !department.getActive()) {

            throw new RuntimeException(
                    "Department is inactive");
        }

        if (departmentHeadRepository
                .existsByDepartmentId(
                        request.getDepartmentId())) {

            throw new RuntimeException(
                    "This department already has a Department Head");
        }

        String temporaryPassword =
                UUID.randomUUID()
                        .toString()
                        .substring(0, 12);

        String activationToken =
                activationService.generateToken();

        String activationTokenHash =
                activationService.hashToken(
                        activationToken);

        User user = new User();

        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPhoneNumber(request.getPhoneNumber());

        user.setPassword(
                passwordEncoder.encode(
                        temporaryPassword));

        user.setRole(Role.DEPARTMENT_HEAD);
        user.setStatus(UserStatus.ACTIVE);
        user.setCreatedAt(LocalDateTime.now());
        user.setFirstLogin(true);

        user.setActivationTokenHash(
                activationTokenHash);

        user.setActivationTokenExpiresAt(
                LocalDateTime.now().plusHours(24));

        user.setActivationTokenUsed(false);

        userRepository.save(user);

        DepartmentHead head =
                new DepartmentHead();

        head.setUser(user);
        head.setDepartment(department);
        head.setDesignation(
                request.getDesignation());

        departmentHeadRepository.save(head);

        // Create activation link for the newly created account
        String activationLink =
                activationUrl
                        + "?token="
                        + activationToken;

        // Return activation link to admin
        return new CreateDepartmentHeadResponse(
                user.getId(),
                head.getId(),
                user.getName(),
                user.getEmail(),
                activationLink,
                department.getName(),
                head.getDesignation()
        );
    }

    // ============================================================
    // GET ALL DEPARTMENT HEADS
    // ============================================================

    public List<DepartmentHeadResponse> getAll() {

        return departmentHeadRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // GET DEPARTMENT HEAD BY ID
    // ============================================================

    public DepartmentHeadResponse getById(Long id) {

        DepartmentHead head =
                departmentHeadRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Department Head not found"));

        return toResponse(head);
    }

    // ============================================================
    // ADMIN ACTIVATE
    // ============================================================

    @Transactional
    public DepartmentHeadResponse activate(Long id) {

        DepartmentHead head =
                departmentHeadRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Department Head not found"));

        Department department =
                head.getDepartment();

        if (department.getActive() == null ||
                !department.getActive()) {

            throw new RuntimeException(
                    "Cannot activate Department Head because department is inactive");
        }

        User user = head.getUser();

        user.setStatus(UserStatus.ACTIVE);

        userRepository.save(user);

        return toResponse(head);
    }

    // ============================================================
    // ADMIN BLOCK
    // ============================================================

    @Transactional
    public DepartmentHeadResponse block(Long id) {

        DepartmentHead head =
                departmentHeadRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Department Head not found"));

        User user = head.getUser();

        user.setStatus(UserStatus.BLOCKED);

        userRepository.save(user);

        return toResponse(head);
    }

    // ============================================================
    // MAP ENTITY -> RESPONSE
    // ============================================================

    private DepartmentHeadResponse toResponse(
            DepartmentHead head) {

        User user = head.getUser();
        Department department = head.getDepartment();

        return new DepartmentHeadResponse(
                head.getId(),
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getPhoneNumber(),
                department.getId(),
                department.getName(),
                head.getDesignation(),
                user.getStatus().name(),
                user.isFirstLogin()
        );
    }
}

