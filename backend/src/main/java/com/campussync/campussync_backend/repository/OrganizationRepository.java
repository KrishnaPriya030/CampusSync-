
package com.campussync.campussync_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.campussync.campussync_backend.entity.Organization;

public interface OrganizationRepository
        extends JpaRepository<Organization, Long> {

    Optional<Organization> findByCode(String code);

    boolean existsByCode(String code);

    @Query("""
        SELECT o
        FROM Organization o
        LEFT JOIN FETCH o.department d
        WHERE o.id = :organizationId
    """)
    Optional<Organization> findByIdWithDepartment(Long organizationId);
}

