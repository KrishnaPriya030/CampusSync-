package com.campussync.campussync_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.OrganizationHead;

public interface OrganizationHeadRepository
        extends JpaRepository<OrganizationHead, Long> {

    Optional<OrganizationHead> findByUserId(Long userId);

    Optional<OrganizationHead> findByOrganizationId(Long organizationId);

    boolean existsByOrganizationId(Long organizationId);
}