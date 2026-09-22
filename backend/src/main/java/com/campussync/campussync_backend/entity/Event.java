package com.campussync.campussync_backend.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import com.campussync.campussync_backend.enums.CapacityType;
import com.campussync.campussync_backend.enums.EventScope;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.PaymentType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "events")
@Getter
@Setter
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "organizer_id", nullable = false)
    private Organizer organizer;

    @NotBlank
    @Column(nullable = false)
    private String title;

    @NotBlank
    @Column(columnDefinition = "TEXT", nullable = false)
    private String description;

    @NotBlank
    @Column(nullable = false)
    private String venue;

    @NotNull
    @Column(nullable = false)
    private LocalDateTime startDateTime;

    @NotNull
    @Column(nullable = false)
    private LocalDateTime endDateTime;

    @NotNull
    @Column(nullable = false)
    private LocalDateTime registrationDeadline;

    /*
     * Determines which authority must approve the event.
     *
     * DEPARTMENT:
     *     Department Head approval required.
     *
     * ORGANIZATION:
     *     Organization Head approval required.
     */
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EventScope scope;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CapacityType capacityType;

    private Integer capacity;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentType paymentType;

    @NotNull
    @DecimalMin(value = "0.00")
    @Column(precision = 10, scale = 2, nullable = false)
    private BigDecimal registrationFee = BigDecimal.ZERO;

    @Column(columnDefinition = "TEXT")
    private String refundPolicy;

    @Column(nullable = false)
    private boolean attendanceEnabled = false;

    @Column(nullable = false)
    private boolean certificateEnabled = false;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EventStatus status = EventStatus.DRAFT;

    @Column(name = "approved_by")
    private Long approvedBy;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(nullable = false)
    private boolean deleted = false;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    // ============================================================
    // EVENT REMINDER TRACKING
    // ============================================================

    /*
     * Prevents the 24-hour reminder from being
     * sent more than once.
     */
    @Column(nullable = false)
    private boolean reminder24HoursSent = false;

    /*
     * Prevents the 1-hour reminder from being
     * sent more than once.
     */
    @Column(nullable = false)
    private boolean reminder1HourSent = false;

    // ============================================================
    // RELATIONSHIPS
    // ============================================================

    @OneToMany(mappedBy = "event")
    private List<EventRegistration> registrations;

    @ManyToOne
    @JoinColumn(name = "certificate_template_id")
    private CertificateTemplate certificateTemplate;
}