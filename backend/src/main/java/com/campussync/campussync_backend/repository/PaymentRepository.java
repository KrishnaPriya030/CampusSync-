package com.campussync.campussync_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Payment;

public interface PaymentRepository
        extends JpaRepository<Payment, Long> {

    Optional<Payment> findByRegistrationId(
            Long registrationId);

    List<Payment> findByRegistrationEventIdOrderByCreatedAtDesc(
            Long eventId);

    List<Payment>
    findByRegistrationEventOrganizerUserIdOrderByCreatedAtDesc(
            Long userId);
}