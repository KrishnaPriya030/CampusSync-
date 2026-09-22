package com.campussync.campussync_backend.service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.core.io.Resource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.CertificateResponse;
import com.campussync.campussync_backend.entity.Attendance;
import com.campussync.campussync_backend.entity.Certificate;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Organizer;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.AttendanceStatus;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.repository.AttendanceRepository;
import com.campussync.campussync_backend.repository.CertificateRepository;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.OrganizerRepository;
import com.campussync.campussync_backend.repository.StudentRepository;

@Service
public class CertificateService {

    private final CertificateRepository certificateRepository;
    private final EventRepository eventRepository;
    private final StudentRepository studentRepository;
    private final OrganizerRepository organizerRepository;
    private final EventRegistrationRepository registrationRepository;
    private final AttendanceRepository attendanceRepository;
    private final CertificatePdfService certificatePdfService;
    private final NotificationService notificationService;

    public CertificateService(
            CertificateRepository certificateRepository,
            EventRepository eventRepository,
            StudentRepository studentRepository,
            OrganizerRepository organizerRepository,
            EventRegistrationRepository registrationRepository,
            AttendanceRepository attendanceRepository,
            CertificatePdfService certificatePdfService,
            NotificationService notificationService) {

        this.certificateRepository = certificateRepository;
        this.eventRepository = eventRepository;
        this.studentRepository = studentRepository;
        this.organizerRepository = organizerRepository;
        this.registrationRepository = registrationRepository;
        this.attendanceRepository = attendanceRepository;
        this.certificatePdfService = certificatePdfService;
        this.notificationService = notificationService;
    }

    // ============================================================
    // ORGANIZER: ISSUE CERTIFICATE
    // ============================================================

    @Transactional
    public CertificateResponse issueCertificate(
            Long userId,
            Long eventId,
            Long studentId) {

        Organizer organizer =
                organizerRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer account not found"));

        Event event =
                eventRepository.findById(eventId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Event not found"));

        if (!event.getOrganizer().getId()
                .equals(organizer.getId())) {

            throw new RuntimeException(
                    "You are not allowed to issue certificates for this event");
        }

        if (!event.isCertificateEnabled()) {

            throw new RuntimeException(
                    "Certificates are not enabled for this event");
        }

        if (event.getCertificateTemplate() == null) {

            throw new RuntimeException(
                    "Certificate template is not configured for this event");
        }

        Student student =
                studentRepository.findById(studentId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Student not found"));

        EventRegistration registration =
                registrationRepository
                        .findByEventIdAndStudentId(
                                eventId,
                                studentId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Student is not registered for this event"));

        if (registration.getStatus()
                != EventRegistrationStatus.REGISTERED) {

            throw new RuntimeException(
                    "Student does not have a valid registration");
        }

        Attendance attendance =
                attendanceRepository
                        .findByRegistrationId(
                                registration.getId())
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Attendance has not been marked for this student"));

        if (attendance.getStatus()
                != AttendanceStatus.PRESENT) {

            throw new RuntimeException(
                    "Certificate can only be issued to students marked PRESENT");
        }

        if (certificateRepository
                .existsByEventIdAndStudentId(
                        eventId,
                        studentId)) {

            throw new RuntimeException(
                    "Certificate has already been issued to this student");
        }

        // --------------------------------------------------------
        // Create Certificate
        // --------------------------------------------------------

        Certificate certificate =
                new Certificate();

        certificate.setEvent(event);
        certificate.setStudent(student);

        // Store the exact template selected by the event.
        certificate.setCertificateTemplate(
                event.getCertificateTemplate());

        certificate.setCertificateNumber(
                generateCertificateNumber());

        certificate.setIssuedAt(
                LocalDateTime.now());

        certificate.setIssuedBy(
                organizer.getUser());

        certificate.setCertificateUrl(null);

        // --------------------------------------------------------
        // Save first
        // --------------------------------------------------------

        Certificate saved =
                certificateRepository.save(certificate);

        // --------------------------------------------------------
        // Generate and save PDF
        // --------------------------------------------------------

        String certificateUrl =
                certificatePdfService
                        .generateAndSaveCertificatePdf(saved);

        // --------------------------------------------------------
        // Store PDF URL
        // --------------------------------------------------------

        saved.setCertificateUrl(
                certificateUrl);

        saved =
                certificateRepository.save(saved);

        // --------------------------------------------------------
        // Notify student
        // --------------------------------------------------------

        notificationService.createNotification(
                student.getUser().getId(),
                "Certificate Issued",
                "Your certificate for the event \""
                        + event.getTitle()
                        + "\" has been issued. You can now download it from CampusSync.",
                NotificationType.CERTIFICATE_ISSUED,
                event
        );

        return toResponse(saved);
    }

    // ============================================================
    // ORGANIZER: GET EVENT CERTIFICATES
    // ============================================================

    @Transactional(readOnly = true)
    public List<CertificateResponse> getEventCertificates(
            Long userId,
            Long eventId) {

        Organizer organizer =
                organizerRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Organizer account not found"));

        Event event =
                eventRepository.findById(eventId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Event not found"));

        if (!event.getOrganizer().getId()
                .equals(organizer.getId())) {

            throw new RuntimeException(
                    "You are not allowed to view certificates for this event");
        }

        return certificateRepository
                .findByEventId(eventId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // STUDENT: GET MY CERTIFICATES
    // ============================================================

    @Transactional(readOnly = true)
    public List<CertificateResponse> getMyCertificates(
            Long userId) {

        Student student =
                studentRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Student account not found"));

        return certificateRepository
                .findByStudentId(student.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ============================================================
    // STUDENT: DOWNLOAD MY CERTIFICATE
    // ============================================================

    @Transactional(readOnly = true)
    public Resource downloadCertificate(
            Long userId,
            Long certificateId) {

        // Find logged-in student
        Student student =
                studentRepository.findByUserId(userId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Student account not found"));

        // Find certificate
        Certificate certificate =
                certificateRepository.findById(certificateId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Certificate not found"));

        // Security check:
        // A student can download only their own certificate.
        if (!certificate.getStudent().getId()
                .equals(student.getId())) {

            throw new RuntimeException(
                    "You are not allowed to download this certificate");
        }

        // Make sure a PDF URL exists.
        if (certificate.getCertificateUrl() == null
                || certificate.getCertificateUrl().isBlank()) {

            throw new RuntimeException(
                    "Certificate PDF is not available");
        }

        /*
         * certificateUrl is stored like:
         *
         * /uploads/certificates/CERT-2026-XXXXXXXX.pdf
         *
         * We only take the filename from the stored URL.
         * This prevents the client/database URL from being
         * used as an arbitrary filesystem path.
         */
        String fileName =
                Paths.get(certificate.getCertificateUrl())
                        .getFileName()
                        .toString();

        Path filePath =
                Paths.get(
                        "uploads",
                        "certificates",
                        fileName)
                        .toAbsolutePath()
                        .normalize();

        Path certificatesDirectory =
                Paths.get(
                        "uploads",
                        "certificates")
                        .toAbsolutePath()
                        .normalize();

        // Security check against path traversal.
        if (!filePath.startsWith(certificatesDirectory)) {

            throw new RuntimeException(
                    "Invalid certificate file path");
        }

        if (!Files.exists(filePath)
                || !Files.isRegularFile(filePath)) {

            throw new RuntimeException(
                    "Certificate PDF file not found");
        }

        Resource resource =
                new FileSystemResource(filePath.toFile());

        if (!resource.exists()
                || !resource.isReadable()) {

            throw new RuntimeException(
                    "Certificate PDF cannot be read");
        }

        return resource;
    }

    // ============================================================
    // GENERATE CERTIFICATE NUMBER
    // ============================================================

    private String generateCertificateNumber() {

        return "CERT-"
                + LocalDateTime.now()
                        .getYear()
                + "-"
                + UUID.randomUUID()
                        .toString()
                        .substring(0, 8)
                        .toUpperCase();
    }

    // ============================================================
    // ENTITY → RESPONSE
    // ============================================================

    private CertificateResponse toResponse(
            Certificate certificate) {

        Event event =
                certificate.getEvent();

        Student student =
                certificate.getStudent();

        User issuedBy =
                certificate.getIssuedBy();

        return new CertificateResponse(
                certificate.getId(),
                certificate.getCertificateNumber(),
                event.getId(),
                event.getTitle(),
                student.getId(),
                student.getUser().getName(),
                student.getRegisterNumber(),
                certificate.getIssuedAt(),
                issuedBy.getId(),
                certificate.getCertificateUrl()
        );
    }
}