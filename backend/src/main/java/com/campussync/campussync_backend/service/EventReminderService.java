package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.EventRepository;

@Service
public class EventReminderService {

    private final EventRepository eventRepository;
    private final EventRegistrationRepository registrationRepository;
    private final NotificationService notificationService;

    public EventReminderService(
            EventRepository eventRepository,
            EventRegistrationRepository registrationRepository,
            NotificationService notificationService) {

        this.eventRepository = eventRepository;
        this.registrationRepository = registrationRepository;
        this.notificationService = notificationService;
    }

    // ============================================================
    // CHECK REMINDERS
    // ============================================================

    /*
     * Runs every minute.
     *
     * It checks whether any published event is currently
     * inside the 24-hour or 1-hour reminder window.
     */
    @Scheduled(fixedRate = 60000)
    @Transactional
    public void processEventReminders() {

        LocalDateTime now =
                LocalDateTime.now();

        process24HourReminders(now);

        process1HourReminders(now);
    }

    // ============================================================
    // 24-HOUR REMINDER
    // ============================================================

    private void process24HourReminders(
            LocalDateTime now) {

        LocalDateTime windowStart =
                now.plusHours(24);

        LocalDateTime windowEnd =
                windowStart.plusMinutes(1);

        List<Event> events =
                eventRepository
                        .findByStatusAndDeletedFalseAndReminder24HoursSentFalseAndStartDateTimeBetween(
                                EventStatus.PUBLISHED,
                                windowStart,
                                windowEnd
                        );

        for (Event event : events) {

            sendReminder(
                    event,
                    "Event Reminder",
                    "Your event \""
                            + event.getTitle()
                            + "\" starts in 24 hours."
            );

            event.setReminder24HoursSent(true);

            eventRepository.save(event);
        }
    }

    // ============================================================
    // 1-HOUR REMINDER
    // ============================================================

    private void process1HourReminders(
            LocalDateTime now) {

        LocalDateTime windowStart =
                now.plusHours(1);

        LocalDateTime windowEnd =
                windowStart.plusMinutes(1);

        List<Event> events =
                eventRepository
                        .findByStatusAndDeletedFalseAndReminder1HourSentFalseAndStartDateTimeBetween(
                                EventStatus.PUBLISHED,
                                windowStart,
                                windowEnd
                        );

        for (Event event : events) {

            sendReminder(
                    event,
                    "Event Reminder",
                    "Your event \""
                            + event.getTitle()
                            + "\" starts in 1 hour."
            );

            event.setReminder1HourSent(true);

            eventRepository.save(event);
        }
    }

    // ============================================================
    // SEND REMINDER
    // ============================================================

    private void sendReminder(
            Event event,
            String title,
            String message) {

        notificationService.notifyRegisteredStudents(
                event.getId(),
                title,
                message,
                NotificationType.EVENT_REMINDER,
                event
        );
    }
}