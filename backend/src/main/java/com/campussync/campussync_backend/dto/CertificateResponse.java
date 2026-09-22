
package com.campussync.campussync_backend.dto;

import java.time.LocalDateTime;

public record CertificateResponse(

        Long certificateId,

        String certificateNumber,

        Long eventId,

        String eventTitle,

        Long studentId,

        String studentName,

        String registerNumber,

        LocalDateTime issuedAt,

        Long issuedByUserId,

        String certificateUrl

) {}

