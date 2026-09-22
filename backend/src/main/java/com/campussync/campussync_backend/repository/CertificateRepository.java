
package com.campussync.campussync_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Certificate;

public interface CertificateRepository
        extends JpaRepository<Certificate, Long> {

    Optional<Certificate> findByEventIdAndStudentId(
            Long eventId,
            Long studentId
    );

    boolean existsByEventIdAndStudentId(
            Long eventId,
            Long studentId
    );

    List<Certificate> findByEventId(
            Long eventId
    );

    List<Certificate> findByStudentId(
            Long studentId
    );
}

