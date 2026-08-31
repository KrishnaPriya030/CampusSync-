package com.campussync.campussync_backend.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.RefundStatus;

import jakarta.persistence.*;

import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "refunds")
@Getter
@Setter
public class Refund {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false)
    @JoinColumn(
        name = "payment_id",
        nullable = false,
        unique = true
    )
    private Payment payment;

    @Column(
        precision = 10,
        scale = 2,
        nullable = false
    )
    private BigDecimal amount;

    @Column(columnDefinition = "TEXT")
    private String reason;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RefundStatus status =
            RefundStatus.PENDING;

    @Column(nullable = false)
    private LocalDateTime requestedAt;

    private LocalDateTime processedAt;

    /*
     * Optional organizer/admin note.
     */
    @Column(columnDefinition = "TEXT")
    private String processingNote;
}