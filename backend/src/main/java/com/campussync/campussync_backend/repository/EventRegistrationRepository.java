package com.campussync.campussync_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

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
}