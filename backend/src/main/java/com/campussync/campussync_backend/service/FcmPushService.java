package com.campussync.campussync_backend.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.entity.DeviceToken;
import com.campussync.campussync_backend.repository.DeviceTokenRepository;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;

@Service
public class FcmPushService {

    private final DeviceTokenRepository deviceTokenRepository;

    public FcmPushService(
            DeviceTokenRepository deviceTokenRepository) {

        this.deviceTokenRepository = deviceTokenRepository;
    }

    // ============================================================
    // SEND PUSH TO ONE USER
    // ============================================================

    public void sendToUser(
            Long userId,
            String title,
            String body) {

        List<DeviceToken> tokens =
                deviceTokenRepository
                        .findByUserIdAndActiveTrue(userId);

        for (DeviceToken deviceToken : tokens) {

            sendToToken(
                    deviceToken,
                    title,
                    body
            );
        }
    }

    // ============================================================
    // SEND PUSH TO ONE DEVICE
    // ============================================================

    private void sendToToken(
            DeviceToken deviceToken,
            String title,
            String body) {

        try {

            AndroidNotification notification =
                    AndroidNotification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .setSound("default")
                            .build();

            AndroidConfig androidConfig =
                    AndroidConfig.builder()
                            .setPriority(
                                    AndroidConfig.Priority.HIGH)
                            .setNotification(notification)
                            .build();

            Message message =
                    Message.builder()
                            .setToken(deviceToken.getToken())
                            .setAndroidConfig(androidConfig)
                            .putData(
                                    "title",
                                    title)
                            .putData(
                                    "body",
                                    body)
                            .build();

            FirebaseMessaging.getInstance()
                    .send(message);

        } catch (Exception e) {

            System.err.println(
                    "FCM push failed for device token: "
                    + deviceToken.getToken());

            System.err.println(
                    "Reason: " + e.getMessage());
        }
    }
}