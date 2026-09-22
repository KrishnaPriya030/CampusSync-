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

    Optional<Payment> findByRegistrationId(
            Long registrationId);

    Optional<Payment> findByRazorpayOrderId(
            String razorpayOrderId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            SELECT p
            FROM Payment p
            WHERE p.razorpayOrderId = :razorpayOrderId
            """)
    Optional<Payment> findByRazorpayOrderIdForUpdate(
            @Param("razorpayOrderId") String razorpayOrderId);

    List<Payment> findByRegistrationEventIdOrderByCreatedAtDesc(
            Long eventId);

    List<Payment>
    findByRegistrationEventOrganizerUserIdOrderByCreatedAtDesc(
            Long userId);
}