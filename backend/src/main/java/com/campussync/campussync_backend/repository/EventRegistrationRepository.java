package com.campussync.campussync_backend.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;

public interface EventRegistrationRepository
        extends JpaRepository<EventRegistration, Long> {

    boolean existsByEventIdAndStudentId(
            Long eventId,
            Long studentId
    );

    long countByEventIdAndStatus(
            Long eventId,
            EventRegistrationStatus status
    );

    List<EventRegistration>
    findByEventIdAndStatusOrderByRegisteredAtAsc(
            Long eventId,
            EventRegistrationStatus status
    );

    Optional<EventRegistration>
    findByEventIdAndStudentId(
            Long eventId,
            Long studentId
    );

    Optional<EventRegistration> findFirstByEventId(
            Long eventId
    );

    List<EventRegistration> findByStudentIdOrderByRegisteredAtDesc(
            Long studentId
    );

    // ============================================================
    // LOCK EVENT REGISTRATION
    // MariaDB-compatible row locking
    // ============================================================

    @Query(
        value = """
            SELECT *
            FROM event_registrations
            WHERE id = :id
            FOR UPDATE
            """,
        nativeQuery = true
    )
    Optional<EventRegistration> findByIdForUpdate(
            @Param("id") Long id
    );

    // ============================================================
    // FIND EXPIRED PAYMENT RESERVATIONS
    // ============================================================

    List<EventRegistration>
    findByStatusAndPaymentExpiresAtLessThanEqual(
            EventRegistrationStatus status,
            LocalDateTime expiryTime
    );
}