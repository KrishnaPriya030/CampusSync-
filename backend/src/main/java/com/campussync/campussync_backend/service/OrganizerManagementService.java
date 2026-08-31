package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.CreateOrganizerRequest;
import com.campussync.campussync_backend.dto.CreateOrganizerResponse;
import com.campussync.campussync_backend.dto.OrganizerResponse;
import com.campussync.campussync_backend.entity.Organizer;
import com.campussync.campussync_backend.entity.Organization;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.exception.ActivationTokenException;
import com.campussync.campussync_backend.repository.OrganizerRepository;
import com.campussync.campussync_backend.repository.OrganizationRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class OrganizerManagementService {

    private final UserRepository userRepository;
    private final OrganizerRepository organizerRepository;
    private final OrganizationRepository organizationRepository;
    private final PasswordEncoder passwordEncoder;
    private final OrganizerActivationService activationService;

    @Value("${campussync.activation-url}")
    private String activationUrl;

    public OrganizerManagementService(
            UserRepository userRepository,
            OrganizerRepository organizerRepository,
            OrganizationRepository organizationRepository,
            PasswordEncoder passwordEncoder,
            OrganizerActivationService activationService) {

        this.userRepository = userRepository;
        this.organizerRepository = organizerRepository;
        this.organizationRepository = organizationRepository;
        this.passwordEncoder = passwordEncoder;
        this.activationService = activationService;
    }

    // ============================================================
    // CREATE ORGANIZER
    // ============================================================

    @Transactional
    public CreateOrganizerResponse create(
            CreateOrganizerRequest request) {

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

        /*
         * Generate a random temporary password.
         *
         * The organizer will replace this password
         * during account activation.
         */
        String temporaryPassword =
                UUID.randomUUID()
                        .toString()
                        .substring(0, 12);

        /*
         * Generate activation token.
         */
        String activationToken =
                activationService.generateToken();

        /*
         * Store only the hash of the activation token.
         */
        String activationTokenHash =
                activationService.hashToken(
                        activationToken);

        User user = new User();

        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPhoneNumber(request.getPhoneNumber());

        /*
         * Temporary/random password.
         */
        user.setPassword(
                passwordEncoder.encode(
                        temporaryPassword));

        user.setRole(Role.ORGANIZER);

        /*
         * Account remains ACTIVE.
         *
         * firstLogin=true prevents normal access
         * until the organizer completes activation.
         */
        user.setStatus(UserStatus.ACTIVE);
        user.setCreatedAt(LocalDateTime.now());
        user.setFirstLogin(true);

        /*
         * Activation token information.
         */
        user.setActivationTokenHash(
                activationTokenHash);

        user.setActivationTokenExpiresAt(
                LocalDateTime.now().plusHours(24));

        user.setActivationTokenUsed(false);

        userRepository.save(user);

        /*
         * Create Organizer record.
         */
        Organizer organizer = new Organizer();

        organizer.setUser(user);
        organizer.setOrganization(organization);
        organizer.setDesignation(
                request.getDesignation());

        organizerRepository.save(organizer);

        /*
         * Frontend activation URL.
         *
         * Example:
         *
         * https://campussync.local/organizer/activate?token=ABC
         */
        String activationLink =
                activationUrl
                        + "?token="
                        + activationToken;

        /*
         * Return activation link to Admin.
         */
        return new CreateOrganizerResponse(
                user.getId(),
                organizer.getId(),
                user.getName(),
                user.getEmail(),
                activationLink,
                organization.getName(),
                organizer.getDesignation()
        );
    }

    // ============================================================
    // GET ALL ORGANIZERS
    // ============================================================

    public List<OrganizerResponse> getAll() {

        return organizerRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // GET ORGANIZER BY ID
    // ============================================================

    public OrganizerResponse getById(Long id) {

        Organizer organizer =
                organizerRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer not found"));

        return toResponse(organizer);
    }

    // ============================================================
    // ADMIN ACTIVATE ORGANIZER
    // ============================================================

    @Transactional
    public OrganizerResponse activate(Long id) {

        Organizer organizer =
                organizerRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer not found"));

        if (!organizer.getOrganization().isActive()) {
            throw new RuntimeException(
                    "Cannot activate organizer because organization is inactive");
        }

        User user = organizer.getUser();

        user.setStatus(UserStatus.ACTIVE);

        userRepository.save(user);

        return toResponse(organizer);
    }

    // ============================================================
    // ADMIN BLOCK ORGANIZER
    // ============================================================

    @Transactional
    public OrganizerResponse block(Long id) {

        Organizer organizer =
                organizerRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer not found"));

        User user = organizer.getUser();

        user.setStatus(UserStatus.BLOCKED);

        userRepository.save(user);

        return toResponse(organizer);
    }

    // ============================================================
    // ORGANIZER ACCOUNT ACTIVATION
    // ============================================================

    @Transactional
    public void activateAccount(
            String token,
            String newPassword,
            String confirmPassword) {

        /*
         * Check password confirmation.
         */
        if (!newPassword.equals(confirmPassword)) {
            throw new RuntimeException(
                    "Passwords do not match");
        }

        /*
         * Hash the token received from frontend.
         */
        String tokenHash =
                activationService.hashToken(token);

        /*
         * Find user using the hashed token.
         */
        User user =
                userRepository.findByActivationTokenHash(
                        tokenHash)
                        .orElseThrow(() ->
                                new ActivationTokenException(
                                        "Invalid activation token"));

        /*
         * Prevent activation-link reuse.
         */
        if (user.isActivationTokenUsed()) {
            throw new ActivationTokenException(
                    "Activation token has already been used");
        }

        /*
         * Check token expiry.
         */
        if (activationService.isExpired(
                user.getActivationTokenExpiresAt())) {

            throw new ActivationTokenException(
                    "Activation token has expired");
        }

        /*
         * Make sure this is an organizer account.
         */
        if (user.getRole() != Role.ORGANIZER) {
            throw new RuntimeException(
                    "Invalid organizer activation");
        }

        /*
         * Make sure the organizer account has
         * not been blocked by the admin.
         */
        if (user.getStatus() == UserStatus.BLOCKED) {
            throw new RuntimeException(
                    "Organizer account is blocked");
        }

        /*
         * Set the organizer's real password.
         */
        user.setPassword(
                passwordEncoder.encode(
                        newPassword));

        /*
         * First login is now completed.
         */
        user.setFirstLogin(false);

        /*
         * Mark activation token as used.
         */
        user.setActivationTokenUsed(true);

        /*
         * Remove token after successful activation.
         */
        user.setActivationTokenHash(null);

        user.setActivationTokenExpiresAt(null);

        userRepository.save(user);
    }

    // ============================================================
    // MAP ORGANIZER ENTITY -> RESPONSE
    // ============================================================

    private OrganizerResponse toResponse(
            Organizer organizer) {

        User user = organizer.getUser();

        Organization organization =
                organizer.getOrganization();

        return new OrganizerResponse(
        organizer.getId(),
        user.getId(),
        user.getName(),
        user.getEmail(),
        user.getPhoneNumber(),
        organization.getId(),
        organization.getName(),
        organizer.getDesignation(),
        user.getStatus().name(),
        user.isFirstLogin()
);
    }
}