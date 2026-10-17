
package com.campussync.campussync_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.campussync.campussync_backend.entity.Payment;

import jakarta.persistence.LockModeType;

public interface PaymentRepository
        extends JpaRepository<Payment, Long> {

    // ============================================================
    // NORMAL READ QUERIES
    // ============================================================

    Optional<Payment> findByRegistrationId(
            Long registrationId);

    Optional<Payment> findByRazorpayOrderId(
            String razorpayOrderId);

    List<Payment> findByRegistrationEventIdOrderByCreatedAtDesc(
            Long eventId);

    List<Payment>
    findByRegistrationEventOrganizerUserIdOrderByCreatedAtDesc(
            Long userId);


    // ============================================================
    // CONCURRENCY CONTROL: LOCK BY PAYMENT ID
    // Use inside @Transactional methods.
    // ============================================================

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            SELECT p
            FROM Payment p
            WHERE p.id = :paymentId
            """)
    Optional<Payment> findByIdForUpdate(
            @Param("paymentId") Long paymentId);


    // ============================================================
    // CONCURRENCY CONTROL: LOCK BY REGISTRATION ID
    // Serializes payment changes for the same registration.
    // ============================================================

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            SELECT p
            FROM Payment p
            WHERE p.registration.id = :registrationId
            """)
    Optional<Payment> findByRegistrationIdForUpdate(
            @Param("registrationId") Long registrationId);


    // ============================================================
    // CONCURRENCY CONTROL: LOCK BY RAZORPAY ORDER ID
    // Retains the existing Razorpay lookup behavior.
    // ============================================================

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            SELECT p
            FROM Payment p
            WHERE p.razorpayOrderId = :razorpayOrderId
            """)
    Optional<Payment> findByRazorpayOrderIdForUpdate(
            @Param("razorpayOrderId") String razorpayOrderId);
}
