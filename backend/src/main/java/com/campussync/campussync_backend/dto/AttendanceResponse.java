
package com.campussync.campussync_backend.dto;

import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.AttendanceStatus;

public record AttendanceResponse(

        Long attendanceId,

        Long registrationId,

        Long eventId,

        Long studentId,

        String studentName,

        String registerNumber,

        AttendanceStatus status,

        LocalDateTime markedAt,

        Long markedByUserId

) {}