package com.campussync.campussync_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Organization;
    
public interface OrganizationRepository
        extends JpaRepository<Organization, Long> {

    Optional<Organization> findByCode(String code);
}