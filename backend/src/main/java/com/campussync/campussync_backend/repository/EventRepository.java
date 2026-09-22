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
import com.campussync.campussync_backend.enums.PaymentType;

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

    // ============================================================
    // STUDENT EVENT SEARCH & FILTER
    // ============================================================

    @Query("""
            SELECT e
            FROM Event e
            JOIN e.organizer o
            JOIN o.organization org
            WHERE e.status = :status
              AND e.deleted = false

              AND (
                    :keyword IS NULL
                    OR LOWER(e.title) LIKE LOWER(CONCAT('%', :keyword, '%'))
                    OR LOWER(e.description) LIKE LOWER(CONCAT('%', :keyword, '%'))
                    OR LOWER(e.venue) LIKE LOWER(CONCAT('%', :keyword, '%'))
                  )

              AND (
                    :departmentId IS NULL
                    OR org.department.id = :departmentId
                  )

              AND (
                    :organizationId IS NULL
                    OR org.id = :organizationId
                  )

              AND (
                    :scope IS NULL
                    OR e.scope = :scope
                  )

              AND (
                    :paymentType IS NULL
                    OR e.paymentType = :paymentType
                  )

              AND (
                    :startDate IS NULL
                    OR e.startDateTime >= :startDate
                  )

              AND (
                    :endDate IS NULL
                    OR e.startDateTime <= :endDate
                  )

            ORDER BY e.startDateTime ASC
            """)
    List<Event> searchPublishedEvents(
            @Param("status") EventStatus status,
            @Param("keyword") String keyword,
            @Param("departmentId") Long departmentId,
            @Param("organizationId") Long organizationId,
            @Param("scope") EventScope scope,
            @Param("paymentType") PaymentType paymentType,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);

    // ============================================================
    // ROW LOCKING
    // ============================================================

    @Query(value = """
            SELECT *
            FROM events
            WHERE id = :id
            FOR UPDATE
            """, nativeQuery = true)
    Optional<Event> findByIdForUpdate(
            @Param("id") Long id);

    // ============================================================
    // EVENT REMINDERS
    // ============================================================

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