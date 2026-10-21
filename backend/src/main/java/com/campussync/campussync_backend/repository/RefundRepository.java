
package com.campussync.campussync_backend.repository;

import java.util.List;

import com.campussync.campussync_backend.entity.Refund;
import com.campussync.campussync_backend.enums.EventScope;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RefundRepository extends JpaRepository<Refund, Long> {

    // ============================================================
    // NORMAL READ QUERIES
    // ============================================================

    List<Refund> findByPaymentId(Long paymentId);

    List<Refund> findByPaymentIdOrderByRequestedAtDesc(Long paymentId);

    List<Refund> findByPaymentRegistrationEventIdOrderByRequestedAtDesc(
            Long eventId);

    List<Refund> findByPaymentRegistrationStudentUserIdOrderByRequestedAtDesc(
            Long userId);

    List<Refund> findByPaymentRegistrationEventOrganizerUserIdOrderByRequestedAtDesc(
            Long userId);


    // ============================================================
    // ORGANIZATION HEAD: EVENT REFUNDS
    // ============================================================

    @Query("""
            SELECT r
            FROM Refund r
            WHERE r.payment.registration.event.deleted = false
              AND r.payment.registration.event.scope = :scope
              AND r.payment.registration.event.organizer.organization.id = :organizationId
            ORDER BY r.requestedAt DESC
            """)
    List<Refund> findOrganizationHeadRefunds(
            @Param("organizationId") Long organizationId,
            @Param("scope") EventScope scope);


    // ============================================================
    // DEPARTMENT HEAD: EVENT REFUNDS
    // ============================================================

    @Query("""
            SELECT r
            FROM Refund r
            WHERE r.payment.registration.event.deleted = false
              AND r.payment.registration.event.scope = :scope
              AND r.payment.registration.event.organizer.organization.department.id = :departmentId
            ORDER BY r.requestedAt DESC
            """)
    List<Refund> findDepartmentHeadRefunds(
            @Param("departmentId") Long departmentId,
            @Param("scope") EventScope scope);

}
