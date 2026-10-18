
package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;

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
    private final EmailService emailService;

    public PasswordResetService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            OrganizerActivationService activationService,
            EmailService emailService) {

        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.activationService = activationService;
        this.emailService = emailService;
    }

    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {

        User user = userRepository
                .findByEmail(request.getEmail())
                .orElse(null);

        // Do not reveal whether an account exists.
        if (user == null) {
            return;
        }

        String token = activationService.generateToken();

        String tokenHash = activationService.hashToken(token);

        user.setPasswordResetTokenHash(tokenHash);
        user.setPasswordResetTokenExpiresAt(
                LocalDateTime.now().plusMinutes(30));
        user.setPasswordResetTokenUsed(false);

        userRepository.save(user);

        // Send the raw token only through the reset email.
        emailService.sendPasswordResetEmail(
                user.getEmail(), token);
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {

        if (!request.getNewPassword()
                .equals(request.getConfirmPassword())) {
            throw new RuntimeException("Passwords do not match");
        }

        String tokenHash =
                activationService.hashToken(request.getToken());

        User user = userRepository
                .findByPasswordResetTokenHash(tokenHash)
                .orElseThrow(() ->
                        new ActivationTokenException(
                                "Invalid password reset token"));

        if (user.isPasswordResetTokenUsed()) {
            throw new ActivationTokenException(
                    "Password reset token has already been used");
        }

        if (activationService.isExpired(
                user.getPasswordResetTokenExpiresAt())) {
            throw new ActivationTokenException(
                    "Password reset token has expired");
        }

        user.setPassword(
                passwordEncoder.encode(request.getNewPassword()));

        user.setFirstLogin(false);
        user.setPasswordResetTokenUsed(true);
        user.setPasswordResetTokenHash(null);
        user.setPasswordResetTokenExpiresAt(null);

        userRepository.save(user);
    }
}
