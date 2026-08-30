package com.campussync.campussync_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.Branch;

public interface BranchRepository extends JpaRepository<Branch, Long> {
}