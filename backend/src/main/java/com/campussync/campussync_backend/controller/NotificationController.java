package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.entity.Notification;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.NotificationService;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(
            NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<List<Notification>> getMyNotifications(
            Authentication authentication) {

        User user = (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                notificationService.getMyNotifications(
                        user.getId()));
    }

    @GetMapping("/unread")
    public ResponseEntity<List<Notification>> getUnreadNotifications(
            Authentication authentication) {

        User user = (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                notificationService.getUnreadNotifications(
                        user.getId()));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Long> getUnreadCount(
            Authentication authentication) {

        User user = (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                notificationService.getUnreadCount(
                        user.getId()));
    }

    @PutMapping("/{notificationId}/read")
    public ResponseEntity<Notification> markAsRead(
            @PathVariable Long notificationId,
            Authentication authentication) {

        User user = (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                notificationService.markAsRead(
                        user.getId(),
                        notificationId));
    }

    @PutMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead(
            Authentication authentication) {

        User user = (User) authentication.getPrincipal();

        notificationService.markAllAsRead(
                user.getId());

        return ResponseEntity.noContent().build();
    }
}