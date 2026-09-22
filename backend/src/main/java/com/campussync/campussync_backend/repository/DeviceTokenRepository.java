package com.campussync.campussync_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.DeviceToken;

public interface DeviceTokenRepository
        extends JpaRepository<DeviceToken, Long> {

    Optional<DeviceToken> findByToken(String token);

    List<DeviceToken> findByUserIdAndActiveTrue(Long userId);

    List<DeviceToken> findByActiveTrue();

    boolean existsByToken(String token);
}