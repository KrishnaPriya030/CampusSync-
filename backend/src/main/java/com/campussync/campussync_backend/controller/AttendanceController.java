
package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.AttendanceResponse;
import com.campussync.campussync_backend.dto.MarkAttendanceRequest;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.AttendanceService;

@RestController
@RequestMapping("/api")
public class AttendanceController {

    private final AttendanceService attendanceService;

    public AttendanceController(
            AttendanceService attendanceService) {

        this.attendanceService = attendanceService;
    }

    // ============================================================
    // ORGANIZER: MARK / UPDATE ATTENDANCE
    // PUT /api/organizer/events/{eventId}/attendance/{registrationId}
    // ============================================================

    @PutMapping(
            "/organizer/events/{eventId}/attendance/{registrationId}")
    public ResponseEntity<AttendanceResponse> markAttendance(
            @PathVariable Long eventId,
            @PathVariable Long registrationId,
            @RequestBody MarkAttendanceRequest request,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                attendanceService.markAttendance(
                        user.getId(),
                        eventId,
                        registrationId,
                        request));
    }

    // ============================================================
    // ORGANIZER: GET EVENT ATTENDANCE
    // GET /api/organizer/events/{eventId}/attendance
    // ============================================================

    @GetMapping(
            "/organizer/events/{eventId}/attendance")
    public ResponseEntity<List<AttendanceResponse>>
    getEventAttendance(
            @PathVariable Long eventId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                attendanceService.getEventAttendance(
                        user.getId(),
                        eventId));
    }

    // ============================================================
    // STUDENT: GET MY ATTENDANCE
    // GET /api/student/registrations/{registrationId}/attendance
    // ============================================================

    @GetMapping(
            "/student/registrations/{registrationId}/attendance")
    public ResponseEntity<AttendanceResponse>
    getMyAttendance(
            @PathVariable Long registrationId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                attendanceService.getMyAttendance(
                        user.getId(),
                        registrationId));
    }

    // ============================================================
    // AUTHENTICATED USER
    // ============================================================

    private User getAuthenticatedUser(
            Authentication authentication) {

        if (authentication == null
                || !authentication.isAuthenticated()) {

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

