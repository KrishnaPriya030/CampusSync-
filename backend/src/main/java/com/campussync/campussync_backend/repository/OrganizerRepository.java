
package com.campussync.campussync_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.campussync.campussync_backend.entity.Organizer;

public interface OrganizerRepository
        extends JpaRepository<Organizer, Long> {

    @Query("""
        SELECT o
        FROM Organizer o
        JOIN FETCH o.user u
        JOIN FETCH o.organization org
        LEFT JOIN FETCH org.department d
        WHERE u.id = :userId
    """)
    Optional<Organizer> findByUserId(Long userId);

    Optional<Organizer> findByUserEmail(String email);

    boolean existsByUserId(Long userId);
}

