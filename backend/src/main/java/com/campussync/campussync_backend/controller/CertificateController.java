
package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.CertificateResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.CertificateService;

@RestController
@RequestMapping("/api")
public class CertificateController {

    private final CertificateService certificateService;

    public CertificateController(
            CertificateService certificateService) {

        this.certificateService = certificateService;
    }

    // ============================================================
    // ORGANIZER: ISSUE CERTIFICATE
    // POST /api/organizer/events/{eventId}/certificates/{studentId}
    // ============================================================

    @PostMapping(
            "/organizer/events/{eventId}/certificates/{studentId}")
    public ResponseEntity<CertificateResponse> issueCertificate(
            @PathVariable Long eventId,
            @PathVariable Long studentId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                certificateService.issueCertificate(
                        user.getId(),
                        eventId,
                        studentId));
    }

    // ============================================================
    // ORGANIZER: GET EVENT CERTIFICATES
    // GET /api/organizer/events/{eventId}/certificates
    // ============================================================

    @GetMapping(
            "/organizer/events/{eventId}/certificates")
    public ResponseEntity<List<CertificateResponse>>
    getEventCertificates(
            @PathVariable Long eventId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                certificateService.getEventCertificates(
                        user.getId(),
                        eventId));
    }

    // ============================================================
    // STUDENT: GET MY CERTIFICATES
    // GET /api/student/certificates
    // ============================================================

    @GetMapping("/student/certificates")
    public ResponseEntity<List<CertificateResponse>>
    getMyCertificates(
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                certificateService.getMyCertificates(
                        user.getId()));
    }

    // ============================================================
    // STUDENT: DOWNLOAD MY CERTIFICATE
    // GET /api/student/certificates/{certificateId}/download
    // ============================================================

    @GetMapping(
            "/student/certificates/{certificateId}/download")
    public ResponseEntity<Resource> downloadCertificate(
            @PathVariable Long certificateId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        Resource resource =
                certificateService.downloadCertificate(
                        user.getId(),
                        certificateId);

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" +
                                resource.getFilename() + "\"")
                .body(resource);
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

