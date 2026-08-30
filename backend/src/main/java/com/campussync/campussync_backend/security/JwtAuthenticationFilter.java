package com.campussync.campussync_backend.security;

import java.io.IOException;
import java.util.List;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.repository.UserRepository;
import com.campussync.campussync_backend.service.JwtService;
import com.campussync.campussync_backend.service.TokenRevocationService;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserRepository userRepository;
    private final TokenRevocationService tokenRevocationService;

    public JwtAuthenticationFilter(
            JwtService jwtService,
            UserRepository userRepository,
            TokenRevocationService tokenRevocationService) {

        this.jwtService = jwtService;
        this.userRepository = userRepository;
        this.tokenRevocationService = tokenRevocationService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader =
                request.getHeader("Authorization");

        if (authHeader == null
                || !authHeader.startsWith("Bearer ")) {

            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);

        try {

            // Check whether JWT was logged out
            if (tokenRevocationService.isRevoked(token)) {

                response.setStatus(
                        HttpServletResponse.SC_UNAUTHORIZED);

                response.setContentType(
                        "application/json");

                response.getWriter().write(
                        "{\"message\":\"Token has been revoked. Please login again.\"}"
                );

                return;
            }

            String email =
                    jwtService.extractEmail(token);

            if (email != null
                    && SecurityContextHolder
                            .getContext()
                            .getAuthentication() == null) {

                User user =
                        userRepository
                                .findByEmail(email)
                                .orElse(null);

                if (user != null) {

                    boolean valid =
                            jwtService.isTokenValid(
                                    token,
                                    user.getEmail());

                    if (valid) {

                        if (user.getStatus()
                                != UserStatus.ACTIVE) {

                            filterChain.doFilter(
                                    request,
                                    response);

                            return;
                        }

                        UsernamePasswordAuthenticationToken
                                authentication =
                                new UsernamePasswordAuthenticationToken(
                                        user,
                                        null,
                                        List.of(
                                                new SimpleGrantedAuthority(
                                                        "ROLE_"
                                                                + user.getRole()
                                                                        .name()
                                                )
                                        )
                                );

                        SecurityContextHolder
                                .getContext()
                                .setAuthentication(
                                        authentication);
                    }
                }
            }

        } catch (Exception e) {

            // Invalid JWT — continue without authentication
            SecurityContextHolder
                    .clearContext();
        }

        filterChain.doFilter(request, response);
    }
}