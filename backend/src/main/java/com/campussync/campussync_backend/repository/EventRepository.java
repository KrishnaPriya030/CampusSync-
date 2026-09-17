package com.campussync.campussync_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.enums.EventStatus;

import jakarta.persistence.LockModeType;

public interface EventRepository
        extends JpaRepository<Event, Long> {

    List<Event> findByOrganizerIdAndDeletedFalseOrderByCreatedAtDesc(
            Long organizerId);

    Optional<Event> findByIdAndDeletedFalse(Long id);

    /*
     * This method will be used later by the registration system.
     *
     * PESSIMISTIC_WRITE ensures that two simultaneous
     * registration requests cannot both modify the same
     * event capacity at the same time.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            SELECT e
            FROM Event e
            WHERE e.id = :id
            AND e.deleted = false
            """)
    Optional<Event> findByIdForUpdate(
            @Param("id") Long id);

    // ============================================================
    // DEPARTMENT HEAD EVENT DASHBOARD
    // ============================================================

    List<Event> findByOrganizerOrganizationDepartmentIdAndDeletedFalseOrderByCreatedAtDesc(
            Long departmentId);

    List<Event> findByOrganizerOrganizationDepartmentIdAndStatusAndDeletedFalseOrderByCreatedAtDesc(
            Long departmentId,
            EventStatus status);

    // ============================================================
    // ORGANIZATION HEAD EVENT DASHBOARD
    // ============================================================

    List<Event> findByOrganizerOrganizationIdAndDeletedFalseOrderByCreatedAtDesc(
            Long organizationId);

    List<Event> findByOrganizerOrganizationIdAndStatusAndDeletedFalseOrderByCreatedAtDesc(
            Long organizationId,
            EventStatus status);
            List<Event> findByStatusAndDeletedFalseOrderByStartDateTimeAsc(
        EventStatus status);
        Optional<Event> findByIdAndStatusAndDeletedFalse(
        Long id,
        EventStatus status);
}