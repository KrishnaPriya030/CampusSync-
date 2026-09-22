package com.campussync.campussync_backend.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.enums.EventScope;
import com.campussync.campussync_backend.enums.EventStatus;

public interface EventRepository extends JpaRepository<Event, Long> {

    List<Event> findByOrganizerIdAndDeletedFalseOrderByCreatedAtDesc(
            Long organizerId);

    Optional<Event> findByIdAndDeletedFalse(Long id);

    List<Event> findByStatusAndDeletedFalse(
            EventStatus status);

    List<Event> findByStatusAndDeletedFalseOrderByStartDateTimeAsc(
            EventStatus status);

    Optional<Event> findByIdAndStatusAndDeletedFalse(
            Long id,
            EventStatus status);

    List<Event> findByOrganizerOrganizationDepartmentIdAndDeletedFalseOrderByCreatedAtDesc(
            Long departmentId);

    List<Event> findByOrganizerOrganizationDepartmentIdAndStatusAndDeletedFalseOrderByCreatedAtDesc(
            Long departmentId,
            EventStatus status);

    List<Event> findByOrganizerOrganizationIdAndDeletedFalseOrderByCreatedAtDesc(
            Long organizationId);

    List<Event> findByOrganizerOrganizationIdAndStatusAndDeletedFalseOrderByCreatedAtDesc(
            Long organizationId,
            EventStatus status);

    List<Event> findByScopeAndStatusAndDeletedFalse(
            EventScope scope,
            EventStatus status);

    @Query(value = """
            SELECT *
            FROM events
            WHERE id = :id
            FOR UPDATE
            """, nativeQuery = true)
    Optional<Event> findByIdForUpdate(
            @Param("id") Long id);

    List<Event>
    findByStatusAndDeletedFalseAndReminder24HoursSentFalseAndStartDateTimeBetween(
            EventStatus status,
            LocalDateTime start,
            LocalDateTime end);

    List<Event>
    findByStatusAndDeletedFalseAndReminder1HourSentFalseAndStartDateTimeBetween(
            EventStatus status,
            LocalDateTime start,
            LocalDateTime end);
}