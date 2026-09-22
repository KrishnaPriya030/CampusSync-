package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.entity.DeviceToken;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.repository.DeviceTokenRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class DeviceTokenService {

    private final DeviceTokenRepository deviceTokenRepository;
    private final UserRepository userRepository;

    public DeviceTokenService(
            DeviceTokenRepository deviceTokenRepository,
            UserRepository userRepository) {

        this.deviceTokenRepository = deviceTokenRepository;
        this.userRepository = userRepository;
    }

    // ============================================================
    // REGISTER / UPDATE DEVICE TOKEN
    // ============================================================

    @Transactional
    public void registerDeviceToken(
            Long userId,
            String token,
            String platform) {

        if (token == null || token.isBlank()) {
            throw new RuntimeException(
                    "Device token is required");
        }

        User user =
                userRepository.findById(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "User not found"));

        String cleanedToken = token.trim();

        DeviceToken deviceToken =
                deviceTokenRepository
                        .findByToken(cleanedToken)
                        .orElse(null);

        LocalDateTime now =
                LocalDateTime.now();

        if (deviceToken == null) {

            deviceToken = new DeviceToken();

            deviceToken.setUser(user);
            deviceToken.setToken(cleanedToken);
            deviceToken.setPlatform(platform);
            deviceToken.setActive(true);
            deviceToken.setCreatedAt(now);
            deviceToken.setLastUsedAt(now);

        } else {

            /*
             * The same device token may already exist.
             *
             * Reactivate it if necessary and associate
             * it with the current user.
             */
            deviceToken.setUser(user);
            deviceToken.setPlatform(platform);
            deviceToken.setActive(true);
            deviceToken.setLastUsedAt(now);
        }

        deviceTokenRepository.save(deviceToken);
    }

    // ============================================================
    // DEACTIVATE DEVICE TOKEN
    // ============================================================

    @Transactional
    public void deactivateDeviceToken(
            Long userId,
            String token) {

        if (token == null || token.isBlank()) {
            throw new RuntimeException(
                    "Device token is required");
        }

        DeviceToken deviceToken =
                deviceTokenRepository
                        .findByToken(token.trim())
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Device token not found"));

        if (!deviceToken.getUser()
                .getId()
                .equals(userId)) {

            throw new RuntimeException(
                    "You are not allowed to modify this device token");
        }

        deviceToken.setActive(false);

        deviceToken.setLastUsedAt(
                LocalDateTime.now());

        deviceTokenRepository.save(deviceToken);
    }

    // ============================================================
    // GET ACTIVE TOKENS FOR USER
    // ============================================================

    @Transactional(readOnly = true)
    public List<DeviceToken> getActiveTokens(
            Long userId) {

        return deviceTokenRepository
                .findByUserIdAndActiveTrue(userId);
    }
}