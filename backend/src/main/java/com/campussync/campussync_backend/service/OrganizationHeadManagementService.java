
package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.CreateOrganizationHeadRequest;
import com.campussync.campussync_backend.dto.CreateOrganizationHeadResponse;
import com.campussync.campussync_backend.dto.OrganizationHeadResponse;
import com.campussync.campussync_backend.entity.Organization;
import com.campussync.campussync_backend.entity.OrganizationHead;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.repository.OrganizationHeadRepository;
import com.campussync.campussync_backend.repository.OrganizationRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class OrganizationHeadManagementService {

    private final UserRepository userRepository;
    private final OrganizationHeadRepository organizationHeadRepository;
    private final OrganizationRepository organizationRepository;
    private final PasswordEncoder passwordEncoder;
    private final OrganizerActivationService activationService;

    @Value("${campussync.activation-url}")
    private String activationUrl;

    public OrganizationHeadManagementService(
            UserRepository userRepository,
            OrganizationHeadRepository organizationHeadRepository,
            OrganizationRepository organizationRepository,
            PasswordEncoder passwordEncoder,
            OrganizerActivationService activationService) {

        this.userRepository = userRepository;
        this.organizationHeadRepository = organizationHeadRepository;
        this.organizationRepository = organizationRepository;
        this.passwordEncoder = passwordEncoder;
        this.activationService = activationService;
    }

    // ============================================================
    // CREATE ORGANIZATION HEAD
    // ============================================================

    @Transactional
    public CreateOrganizationHeadResponse create(
            CreateOrganizationHeadRequest request) {

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException(
                    "Email already exists");
        }

        Organization organization =
                organizationRepository.findById(
                        request.getOrganizationId())
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization not found"));

        if (!organization.isActive()) {
            throw new RuntimeException(
                    "Organization is inactive");
        }

        if (organizationHeadRepository
                .existsByOrganizationId(
                        request.getOrganizationId())) {

            throw new RuntimeException(
                    "This organization already has an Organization Head");
        }

        // Initial password = Date of Birth (ddMMyyyy)
        String temporaryPassword =
                request.getDateOfBirth()
                        .format(
                                DateTimeFormatter.ofPattern(
                                        "ddMMyyyy"));

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

        user.setRole(Role.ORGANIZATION_HEAD);
        user.setStatus(UserStatus.ACTIVE);
        user.setCreatedAt(LocalDateTime.now());

        // Force password change on first login
        user.setFirstLogin(true);

        user.setActivationTokenHash(
                activationTokenHash);

        user.setActivationTokenExpiresAt(
                LocalDateTime.now().plusHours(24));

        user.setActivationTokenUsed(false);

        userRepository.save(user);

        OrganizationHead organizationHead =
                new OrganizationHead();

        organizationHead.setUser(user);
        organizationHead.setOrganization(
                organization);

        organizationHead.setDesignation(
                request.getDesignation());

        organizationHeadRepository.save(
                organizationHead);

        // Create activation link
        String activationLink =
                activationUrl
                        + "?token="
                        + activationToken;

        // Return activation link to admin
        return new CreateOrganizationHeadResponse(
                user.getId(),
                organizationHead.getId(),
                user.getName(),
                user.getEmail(),
                activationLink,
                organization.getName(),
                organizationHead.getDesignation()
        );
    }

    // ============================================================
    // GET ALL ORGANIZATION HEADS
    // ============================================================

    public List<OrganizationHeadResponse> getAll() {

        return organizationHeadRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // GET ORGANIZATION HEAD BY ID
    // ============================================================

    public OrganizationHeadResponse getById(Long id) {

        OrganizationHead head =
                organizationHeadRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization Head not found"));

        return toResponse(head);
    }

    // ============================================================
    // ADMIN ACTIVATE
    // ============================================================

    @Transactional
    public OrganizationHeadResponse activate(Long id) {

        OrganizationHead head =
                organizationHeadRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization Head not found"));

        if (!head.getOrganization().isActive()) {
            throw new RuntimeException(
                    "Cannot activate Organization Head because organization is inactive");
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
    public OrganizationHeadResponse block(Long id) {

        OrganizationHead head =
                organizationHeadRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organization Head not found"));

        User user = head.getUser();

        user.setStatus(UserStatus.BLOCKED);

        userRepository.save(user);

        return toResponse(head);
    }

    // ============================================================
    // MAP ENTITY -> RESPONSE
    // ============================================================

    private OrganizationHeadResponse toResponse(
            OrganizationHead head) {

        User user = head.getUser();

        Organization organization =
                head.getOrganization();

        return new OrganizationHeadResponse(
                head.getId(),
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getPhoneNumber(),
                organization.getId(),
                organization.getName(),
                head.getDesignation(),
                user.getStatus().name(),
                user.isFirstLogin()
        );
    }
}

