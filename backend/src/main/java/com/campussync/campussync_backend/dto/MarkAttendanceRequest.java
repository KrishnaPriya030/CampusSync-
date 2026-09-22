package com.campussync.campussync_backend.dto;

import com.campussync.campussync_backend.enums.AttendanceStatus;

import jakarta.validation.constraints.NotNull;

public record MarkAttendanceRequest(

        @NotNull
        AttendanceStatus status

) {}