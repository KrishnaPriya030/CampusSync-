package com.campussync.campussync_backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.campussync.campussync_backend.dto.LoginRequest;
import com.campussync.campussync_backend.dto.LoginResponse;
import com.campussync.campussync_backend.service.AuthService;
import com.campussync.campussync_backend.service.TokenRevocationService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final TokenRevocationService tokenRevocationService;

    public AuthController(
            AuthService authService,
            TokenRevocationService tokenRevocationService) {

        this.authService = authService;
        this.tokenRevocationService = tokenRevocationService;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest request) {

        LoginResponse response =
                authService.login(request);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(
            HttpServletRequest request) {

        String authHeader =
                request.getHeader("Authorization");

        if (authHeader == null
                || !authHeader.startsWith("Bearer ")) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            "Authorization token is required"
                    ));
        }

        String token =
                authHeader.substring(7);

        tokenRevocationService.revoke(token);

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Logout successful"
                )
        );
    }
}