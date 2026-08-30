package com.campussync.campussync_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.campussync.campussync_backend.entity.RevokedToken;

public interface RevokedTokenRepository
        extends JpaRepository<RevokedToken, Long> {

    Optional<RevokedToken> findByTokenId(String tokenId);

    boolean existsByTokenId(String tokenId);
}