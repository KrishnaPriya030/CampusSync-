package com.campussync.campussync_backend.repository;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Student;

public interface StudentRepository extends JpaRepository<Student, Long> {
 Optional<Student> findByUserId(Long userId);
}