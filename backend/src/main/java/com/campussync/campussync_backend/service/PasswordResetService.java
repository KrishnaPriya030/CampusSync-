package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.ForgotPasswordRequest;
import com.campussync.campussync_backend.dto.ResetPasswordRequest;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.exception.ActivationTokenException;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class PasswordResetService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OrganizerActivationService activationService;

    public PasswordResetService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            OrganizerActivationService activationService) {

        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.activationService = activationService;
    }

    @Transactional
    public String forgotPassword(
            ForgotPasswordRequest request) {

        User user = userRepository
                .findByEmail(request.getEmail())
                .orElseThrow(() ->
                        new RuntimeException(
                                "User not found"));

        String token =
                UUID.randomUUID().toString();

        String tokenHash =
                activationService.hashToken(token);

        user.setPasswordResetTokenHash(tokenHash);

        user.setPasswordResetTokenExpiresAt(
                LocalDateTime.now().plusMinutes(30));

        user.setPasswordResetTokenUsed(false);

        userRepository.save(user);

        return token;
    }

    @Transactional
    public void resetPassword(
            ResetPasswordRequest request) {

        if (!request.getNewPassword()
                .equals(request.getConfirmPassword())) {

            throw new RuntimeException(
                    "Passwords do not match");
        }

        String tokenHash =
                activationService.hashToken(
                        request.getToken());

        User user = userRepository
                .findByPasswordResetTokenHash(
                        tokenHash)
                .orElseThrow(() ->
                        new ActivationTokenException(
                                "Invalid password reset token"));

        if (user.isPasswordResetTokenUsed()) {

            throw new ActivationTokenException(
                    "Password reset token has already been used");
        }

        if (user.getPasswordResetTokenExpiresAt()
                == null
                || user.getPasswordResetTokenExpiresAt()
                        .isBefore(LocalDateTime.now())) {

            throw new ActivationTokenException(
                    "Password reset token has expired");
        }

        user.setPassword(
                passwordEncoder.encode(
                        request.getNewPassword()));

        user.setFirstLogin(false);

        user.setPasswordResetTokenUsed(true);

        user.setPasswordResetTokenHash(null);

        user.setPasswordResetTokenExpiresAt(null);

        userRepository.save(user);
    }
}