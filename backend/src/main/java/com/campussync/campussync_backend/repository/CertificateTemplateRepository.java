
package com.campussync.campussync_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.CertificateTemplate;

public interface CertificateTemplateRepository
        extends JpaRepository<CertificateTemplate, Long> {

    Optional<CertificateTemplate> findByName(String name);

    boolean existsByName(String name);
}

