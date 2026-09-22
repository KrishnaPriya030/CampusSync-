package com.campussync.campussync_backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.DeviceTokenService;

@RestController
@RequestMapping("/api/notifications/device-token")
public class DeviceTokenController {

    private final DeviceTokenService deviceTokenService;

    public DeviceTokenController(
            DeviceTokenService deviceTokenService) {

        this.deviceTokenService = deviceTokenService;
    }

    // ============================================================
    // REGISTER / UPDATE FCM DEVICE TOKEN
    // ============================================================

    @PostMapping
    public ResponseEntity<Map<String, String>> registerDeviceToken(
            @RequestBody Map<String, String> request,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        String token = request.get("token");
        String platform = request.get("platform");

        deviceTokenService.registerDeviceToken(
                user.getId(),
                token,
                platform);

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Device token registered successfully"
                )
        );
    }

    // ============================================================
    // DEACTIVATE FCM DEVICE TOKEN
    // ============================================================

    @DeleteMapping
    public ResponseEntity<Map<String, String>> deactivateDeviceToken(
            @RequestBody Map<String, String> request,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        String token = request.get("token");

        deviceTokenService.deactivateDeviceToken(
                user.getId(),
                token);

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Device token deactivated successfully"
                )
        );
    }

    // ============================================================
    // AUTHENTICATED USER
    // ============================================================

    private User getAuthenticatedUser(
            Authentication authentication) {

        if (authentication == null ||
                !authentication.isAuthenticated()) {

            throw new RuntimeException(
                    "Authentication required");
        }

        Object principal =
                authentication.getPrincipal();

        if (!(principal instanceof User)) {

            throw new RuntimeException(
                    "Invalid authenticated user");
        }

        return (User) principal;
    }
}   