package com.campussync.campussync_backend.entity;

import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.EventRegistrationStatus;

import jakarta.persistence.*;

import lombok.Getter;
import lombok.Setter;

@Entity
@Table(
    name = "event_registrations",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_event_student",
            columnNames = {
                "event_id",
                "student_id"
            }
        )
    }
)
@Getter
@Setter
public class EventRegistration {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(
        name = "event_id",
        nullable = false
    )
    private Event event;

    @ManyToOne(optional = false)
    @JoinColumn(
        name = "student_id",
        nullable = false
    )
    private Student student;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EventRegistrationStatus status =
            EventRegistrationStatus.REGISTERED;

    @Column(nullable = false)
    private LocalDateTime registeredAt;

    /*
     * Used for paid-event temporary seat reservations.
     *
     * Example:
     *
     * PAYMENT_PENDING
     *       ↓
     * paymentExpiresAt
     *       ↓
     * payment completed → REGISTERED
     *
     * payment expires → CANCELLED
     */
    private LocalDateTime paymentExpiresAt;

    /*
     * Set when payment is successfully completed
     * and registration becomes confirmed.
     */
    private LocalDateTime confirmedAt;
    
@OneToOne(mappedBy = "registration")
private Payment payment;
}