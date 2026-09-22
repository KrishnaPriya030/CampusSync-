package com.campussync.campussync_backend.entity;

import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.AttendanceStatus;

import jakarta.persistence.*;

import lombok.Getter;
import lombok.Setter;

@Entity
@Table(
    name = "attendance",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_attendance_registration",
            columnNames = "registration_id"
        )
    }
)
@Getter
@Setter
public class Attendance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false)
    @JoinColumn(
        name = "registration_id",
        nullable = false
    )
    private EventRegistration registration;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AttendanceStatus status;

    @Column(nullable = false)
    private LocalDateTime markedAt;

    @ManyToOne(optional = false)
    @JoinColumn(
        name = "marked_by_user_id",
        nullable = false
    )
    private User markedBy;
}