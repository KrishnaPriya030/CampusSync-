package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Notification;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.NotificationRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final EventRegistrationRepository eventRegistrationRepository;
    private final FcmPushService fcmPushService;

    public NotificationService(
            NotificationRepository notificationRepository,
            UserRepository userRepository,
            EventRegistrationRepository eventRegistrationRepository,
            FcmPushService fcmPushService) {

        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.eventRegistrationRepository = eventRegistrationRepository;
        this.fcmPushService = fcmPushService;
    }

    // ============================================================
    // CREATE NOTIFICATION FOR ONE USER
    // ============================================================

    @Transactional
    public Notification createNotification(
            Long userId,
            String title,
            String message,
            NotificationType type,
            Event event) {

        User user =
                userRepository.findById(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "User not found"));

        Notification notification =
                new Notification();

        notification.setUser(user);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setType(type);
        notification.setEvent(event);
        notification.setRead(false);
        notification.setCreatedAt(
                LocalDateTime.now());

        Notification savedNotification =
                notificationRepository.save(notification);

        // ========================================================
        // SEND FCM PUSH
        // ========================================================

        fcmPushService.sendToUser(
                userId,
                title,
                message
        );

        return savedNotification;
    }

    // ============================================================
    // NOTIFY ALL USERS
    //
    // Used for:
    // NEW_EVENT
    // ============================================================

    @Transactional
    public void notifyAllUsers(
            String title,
            String message,
            NotificationType type,
            Event event) {

        List<User> users =
                userRepository.findAll();

        for (User user : users) {

            if (user.getStatus() == null) {
                continue;
            }

            createNotification(
                    user.getId(),
                    title,
                    message,
                    type,
                    event
            );
        }
    }

    // ============================================================
    // NOTIFY ALL REGISTERED STUDENTS
    //
    // Used for:
    // EVENT_REMINDER
    // EVENT_UPDATED
    // EVENT_CANCELLED
    // ============================================================

    @Transactional
    public void notifyRegisteredStudents(
            Long eventId,
            String title,
            String message,
            NotificationType type,
            Event event) {

        List<EventRegistration> registrations =
                eventRegistrationRepository
                        .findByEventIdAndStatusOrderByRegisteredAtAsc(
                                eventId,
                                EventRegistrationStatus.REGISTERED
                        );

        for (EventRegistration registration :
                registrations) {

            Long userId =
                    registration
                            .getStudent()
                            .getUser()
                            .getId();

            createNotification(
                    userId,
                    title,
                    message,
                    type,
                    event
            );
        }
    }

    // ============================================================
    // GET MY NOTIFICATIONS
    // ============================================================

    @Transactional(readOnly = true)
    public List<Notification> getMyNotifications(
            Long userId) {

        return notificationRepository
                .findByUserIdOrderByCreatedAtDesc(userId);
    }

    // ============================================================
    // GET UNREAD NOTIFICATIONS
    // ============================================================

    @Transactional(readOnly = true)
    public List<Notification> getUnreadNotifications(
            Long userId) {

        return notificationRepository
                .findByUserIdAndIsReadFalseOrderByCreatedAtDesc(
                        userId);
    }

    // ============================================================
    // UNREAD COUNT
    // ============================================================

    @Transactional(readOnly = true)
    public long getUnreadCount(
            Long userId) {

        return notificationRepository
                .countByUserIdAndIsReadFalse(userId);
    }

    // ============================================================
    // MARK ONE AS READ
    // ============================================================

    @Transactional
    public Notification markAsRead(
            Long userId,
            Long notificationId) {

        Notification notification =
                notificationRepository
                        .findById(notificationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Notification not found"));

        if (!notification.getUser()
                .getId()
                .equals(userId)) {

            throw new RuntimeException(
                    "You are not allowed to modify this notification");
        }

        notification.setRead(true);

        return notificationRepository.save(
                notification);
    }

    // ============================================================
    // MARK ALL AS READ
    // ============================================================

    @Transactional
    public void markAllAsRead(
            Long userId) {

        List<Notification> notifications =
                notificationRepository
                        .findByUserIdAndIsReadFalseOrderByCreatedAtDesc(
                                userId);

        for (Notification notification :
                notifications) {

            notification.setRead(true);
        }

        notificationRepository.saveAll(
                notifications);
    }
}