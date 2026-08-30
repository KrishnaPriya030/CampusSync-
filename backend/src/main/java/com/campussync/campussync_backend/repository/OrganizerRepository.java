package com.campussync.campussync_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Organizer;

public interface OrganizerRepository
        extends JpaRepository<Organizer, Long> {

    Optional<Organizer> findByUserId(Long userId);

    Optional<Organizer> findByUserEmail(String email);

    boolean existsByUserId(Long userId);
}