
package com.campussync.campussync_backend.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;

import jakarta.persistence.LockModeType;

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
    // LOCK EVENT REGISTRATION BY ID
    // Must be called inside a transaction.
    // ============================================================

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            SELECT er
            FROM EventRegistration er
            WHERE er.id = :id
            """)
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
