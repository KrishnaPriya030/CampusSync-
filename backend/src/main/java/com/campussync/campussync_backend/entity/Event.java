package com.campussync.campussync_backend.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.CapacityType;
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
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import jakarta.persistence.OneToMany;

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

    /*
     * Every event belongs to exactly one organizer.
     */
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

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CapacityType capacityType;

    /*
     * Null when capacityType = UNLIMITED.
     */
    private Integer capacity;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentType paymentType;

    /*
     * 0 for FREE events.
     */
    @NotNull
    @DecimalMin(value = "0.00")
    @Column(precision = 10, scale = 2, nullable = false)
    private BigDecimal registrationFee = BigDecimal.ZERO;

    /*
     * Stored with the event so historical registrations
     * retain the policy that was displayed to students.
     */
    @Column(columnDefinition = "TEXT")
    private String refundPolicy;

    /*
     * Optional attendance.
     */
    @Column(nullable = false)
    private boolean attendanceEnabled = false;

    /*
     * Optional certificates.
     * Backend validation will require attendanceEnabled
     * when this is true.
     */
    @Column(nullable = false)
    private boolean certificateEnabled = false;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EventStatus status = EventStatus.DRAFT;

    /*
     * We use soft deletion instead of physical deletion.
     */
    @Column(nullable = false)
    private boolean deleted = false;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
    @OneToMany(
    mappedBy = "event"
)
private List<EventRegistration> registrations;


}