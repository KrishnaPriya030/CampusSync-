package com.campussync.campussync_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Student;

public interface StudentRepository extends JpaRepository<Student, Long> {

}