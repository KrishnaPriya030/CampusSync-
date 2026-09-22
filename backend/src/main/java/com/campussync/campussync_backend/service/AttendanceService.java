
package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.AttendanceResponse;
import com.campussync.campussync_backend.dto.MarkAttendanceRequest;
import com.campussync.campussync_backend.entity.Attendance;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Organizer;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.repository.AttendanceRepository;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.OrganizerRepository;

@Service
public class AttendanceService {

    private final AttendanceRepository attendanceRepository;
    private final EventRegistrationRepository registrationRepository;
    private final OrganizerRepository organizerRepository;
    private final EventRepository eventRepository;

    public AttendanceService(
            AttendanceRepository attendanceRepository,
            EventRegistrationRepository registrationRepository,
            OrganizerRepository organizerRepository,
            EventRepository eventRepository) {

        this.attendanceRepository = attendanceRepository;
        this.registrationRepository = registrationRepository;
        this.organizerRepository = organizerRepository;
        this.eventRepository = eventRepository;
    }

    // ============================================================
    // ORGANIZER: MARK / UPDATE ATTENDANCE
    // ============================================================

    @Transactional
    public AttendanceResponse markAttendance(
            Long userId,
            Long eventId,
            Long registrationId,
            MarkAttendanceRequest request) {

        Organizer organizer =
                organizerRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer account not found"));

        EventRegistration registration =
                registrationRepository.findById(registrationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Registration not found"));

        Event event =
                registration.getEvent();

        // --------------------------------------------------------
        // Make sure registration belongs to requested event
        // --------------------------------------------------------

        if (!event.getId().equals(eventId)) {
            throw new RuntimeException(
                    "Registration does not belong to this event");
        }

        // --------------------------------------------------------
        // Make sure organizer owns this event
        // --------------------------------------------------------

        if (!event.getOrganizer().getId()
                .equals(organizer.getId())) {

            throw new RuntimeException(
                    "You are not allowed to manage attendance for this event");
        }

        // --------------------------------------------------------
        // Attendance must be enabled
        // --------------------------------------------------------

        if (!event.isAttendanceEnabled()) {
            throw new RuntimeException(
                    "Attendance is not enabled for this event");
        }

        // --------------------------------------------------------
        // Only registered students can have attendance
        // --------------------------------------------------------

        if (registration.getStatus()
                != EventRegistrationStatus.REGISTERED) {

            throw new RuntimeException(
                    "Only registered students can have attendance marked");
        }

        // --------------------------------------------------------
        // Find existing attendance or create new record
        // --------------------------------------------------------

        Attendance attendance =
                attendanceRepository
                        .findByRegistrationId(registrationId)
                        .orElseGet(() -> {

                            Attendance newAttendance =
                                    new Attendance();

                            newAttendance.setRegistration(
                                    registration);

                            return newAttendance;
                        });

        // --------------------------------------------------------
        // Mark / update attendance
        // --------------------------------------------------------

        attendance.setStatus(request.status());

        attendance.setMarkedAt(
                LocalDateTime.now());

        attendance.setMarkedBy(
                organizer.getUser());

        return toResponse(
                attendanceRepository.save(attendance));
    }

    // ============================================================
    // ORGANIZER: GET EVENT ATTENDANCE
    // ============================================================

    @Transactional(readOnly = true)
    public List<AttendanceResponse> getEventAttendance(
            Long userId,
            Long eventId) {

        Organizer organizer =
                organizerRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer account not found"));

        // --------------------------------------------------------
        // Find event directly
        // --------------------------------------------------------

        Event event =
                getEvent(eventId);

        // --------------------------------------------------------
        // Make sure organizer owns the event
        // --------------------------------------------------------

        if (!event.getOrganizer().getId()
                .equals(organizer.getId())) {

            throw new RuntimeException(
                    "You are not allowed to view attendance for this event");
        }

        // --------------------------------------------------------
        // Attendance must be enabled
        // --------------------------------------------------------

        if (!event.isAttendanceEnabled()) {
            throw new RuntimeException(
                    "Attendance is not enabled for this event");
        }

        // --------------------------------------------------------
        // Get all attendance records for this event
        // --------------------------------------------------------

        return attendanceRepository
                .findByRegistrationEventId(eventId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // STUDENT: GET MY ATTENDANCE
    // ============================================================

    @Transactional(readOnly = true)
    public AttendanceResponse getMyAttendance(
            Long userId,
            Long registrationId) {

        Attendance attendance =
                attendanceRepository
                        .findByRegistrationId(registrationId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Attendance record not found"));

        // --------------------------------------------------------
        // Make sure attendance belongs to logged-in student
        // --------------------------------------------------------

        if (!attendance.getRegistration()
                .getStudent()
                .getUser()
                .getId()
                .equals(userId)) {

            throw new RuntimeException(
                    "You are not allowed to view this attendance");
        }

        return toResponse(attendance);
    }

    // ============================================================
    // HELPER: FIND EVENT
    // ============================================================

    private Event getEvent(Long eventId) {

        return eventRepository
                .findById(eventId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Event not found"));
    }

    // ============================================================
    // HELPER: CONVERT ENTITY TO RESPONSE
    // ============================================================

    private AttendanceResponse toResponse(
            Attendance attendance) {

        EventRegistration registration =
                attendance.getRegistration();

        Event event =
                registration.getEvent();

        User markedBy =
                attendance.getMarkedBy();

        return new AttendanceResponse(
                attendance.getId(),
                registration.getId(),
                event.getId(),
                registration.getStudent().getId(),
                registration.getStudent()
                        .getUser().getName(),
                registration.getStudent()
                        .getRegisterNumber(),
                attendance.getStatus(),
                attendance.getMarkedAt(),
                markedBy.getId()
        );
    }
}
