package com.campussync.campussync_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Attendance;

public interface AttendanceRepository
        extends JpaRepository<Attendance, Long> {

    Optional<Attendance> findByRegistrationId(
            Long registrationId);

    List<Attendance> findByRegistrationEventId(
            Long eventId);

    boolean existsByRegistrationId(
            Long registrationId);
}