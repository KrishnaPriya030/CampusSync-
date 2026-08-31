package com.campussync.campussync_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Refund;
import com.campussync.campussync_backend.enums.RefundStatus;

public interface RefundRepository
        extends JpaRepository<Refund, Long> {

    Optional<Refund> findByPaymentId(
            Long paymentId);

    List<Refund>
    findByPaymentRegistrationEventOrganizerUserIdOrderByRequestedAtDesc(
            Long userId);

    List<Refund>
    findByPaymentRegistrationStudentUserIdOrderByRequestedAtDesc(
            Long userId);

    List<Refund>
    findByPaymentRegistrationEventIdOrderByRequestedAtDesc(
            Long eventId);

    List<Refund>
    findByStatusOrderByRequestedAtDesc(
            RefundStatus status);
}