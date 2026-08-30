package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

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
         * The organizer will replace it during activation.
         */
        String temporaryPassword =
                java.util.UUID.randomUUID()
                        .toString()
                        .substring(0, 12);

        /*
         * Generate activation token.
         */
        String activationToken =
                activationService.generateToken();

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
         * Organizer account is active,
         * but firstLogin prevents normal access
         * until the organizer sets a password.
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
         */
        String activationLink =
                "http://localhost:3000/organizer/activate?token="
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

    public List<OrganizerResponse> getAll() {

        return organizerRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public OrganizerResponse getById(Long id) {

        Organizer organizer =
                organizerRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer not found"));

        return toResponse(organizer);
    }

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

    /*
     * Organizer activates their account using
     * the activation link generated by Admin.
     */
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
         * Find user using hashed token.
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
         * Set the organizer's real password.
         */
        user.setPassword(
                passwordEncoder.encode(newPassword));

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
                user.getStatus().name()
        );
    }
}   