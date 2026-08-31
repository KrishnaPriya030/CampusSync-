package com.campussync.campussync_backend.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.campussync.campussync_backend.enums.PaymentStatus;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(
    name = "payments",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_payment_registration",
            columnNames = "registration_id"
        )
    }
)
@Getter
@Setter
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false)
    @JoinColumn(
        name = "registration_id",
        nullable = false,
        unique = true
    )
    private EventRegistration registration;

    @Column(
        precision = 10,
        scale = 2,
        nullable = false
    )
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentStatus status =
            PaymentStatus.PENDING;

    /*
     * Razorpay order created by the backend.
     */
    @Column(unique = true)
    private String razorpayOrderId;

    /*
     * Set after successful payment.
     */
    private String razorpayPaymentId;

    /*
     * Signature returned by Razorpay Checkout.
     */
    @Column(length = 500)
    private String razorpaySignature;

    /*
     * Kept for compatibility with our previous
     * manual-payment design.
     *
     * We won't use UTR as the primary payment
     * verification mechanism anymore.
     */
    private String paymentReference;

    private LocalDateTime paidAt;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}