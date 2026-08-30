package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.time.ZoneId;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.entity.RevokedToken;
import com.campussync.campussync_backend.repository.RevokedTokenRepository;

@Service
public class TokenRevocationService {

    private final RevokedTokenRepository revokedTokenRepository;
    private final JwtService jwtService;

    public TokenRevocationService(
            RevokedTokenRepository revokedTokenRepository,
            JwtService jwtService) {

        this.revokedTokenRepository = revokedTokenRepository;
        this.jwtService = jwtService;
    }

    @Transactional
    public void revoke(String token) {

        String tokenId = jwtService.extractTokenId(token);

        if (revokedTokenRepository.existsByTokenId(tokenId)) {
            return;
        }

        RevokedToken revokedToken = new RevokedToken();

        revokedToken.setTokenId(tokenId);

        revokedToken.setExpiresAt(
                jwtService.extractExpiration(token)
                        .toInstant()
                        .atZone(ZoneId.systemDefault())
                        .toLocalDateTime()
        );

        revokedToken.setRevokedAt(
                LocalDateTime.now()
        );

        revokedTokenRepository.save(revokedToken);
    }

    public boolean isRevoked(String token) {

        String tokenId = jwtService.extractTokenId(token);

        return revokedTokenRepository
                .existsByTokenId(tokenId);
    }
}