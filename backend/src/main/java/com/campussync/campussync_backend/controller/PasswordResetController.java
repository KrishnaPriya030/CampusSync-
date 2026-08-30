package com.campussync.campussync_backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.ForgotPasswordRequest;
import com.campussync.campussync_backend.dto.ResetPasswordRequest;
import com.campussync.campussync_backend.service.PasswordResetService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    public PasswordResetController(
            PasswordResetService passwordResetService) {

        this.passwordResetService =
                passwordResetService;
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(
            @Valid @RequestBody
            ForgotPasswordRequest request) {

        String token =
                passwordResetService
                        .forgotPassword(request);

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Password reset token generated",
                        "token",
                        token
                )
        );
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(
            @Valid @RequestBody
            ResetPasswordRequest request) {

        passwordResetService.resetPassword(
                request);

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Password reset successfully"
                )
        );
    }
}