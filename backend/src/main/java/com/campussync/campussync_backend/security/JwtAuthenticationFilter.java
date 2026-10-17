
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

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7).trim();

        if (token.isEmpty()) {
            rejectRequest(
                    response,
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Invalid authentication token");
            return;
        }

        try {
            if (tokenRevocationService.isRevoked(token)) {
                rejectRequest(
                        response,
                        HttpServletResponse.SC_UNAUTHORIZED,
                        "Token has been revoked. Please log in again");
                return;
            }

            String email = jwtService.extractEmail(token);

            if (email == null || email.isBlank()) {
                SecurityContextHolder.clearContext();
                rejectRequest(
                        response,
                        HttpServletResponse.SC_UNAUTHORIZED,
                        "Invalid authentication token");
                return;
            }

            // Stateless API requests should not carry an existing
            // authenticated context from another request.
            User user = userRepository.findByEmail(email).orElse(null);

            if (user == null
                    || !jwtService.isTokenValid(token, user.getEmail())) {

                SecurityContextHolder.clearContext();
                rejectRequest(
                        response,
                        HttpServletResponse.SC_UNAUTHORIZED,
                        "Invalid authentication token");
                return;
            }

            // Do not allow blocked, inactive, or otherwise non-active accounts.
            if (user.getStatus() != UserStatus.ACTIVE) {
                SecurityContextHolder.clearContext();

                rejectRequest(
                        response,
                        HttpServletResponse.SC_FORBIDDEN,
                        "Your account is not active");
                return;
            }

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            user,
                            null,
                            List.of(
                                    new SimpleGrantedAuthority(
                                            "ROLE_" + user.getRole().name())
                            )
                    );

            SecurityContextHolder.clearContext();
            SecurityContextHolder.getContext()
                    .setAuthentication(authentication);

        } catch (Exception exception) {
            // Fail closed: an invalid token must not establish
            // an authenticated security context.
            SecurityContextHolder.clearContext();

            rejectRequest(
                    response,
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Invalid or expired authentication token");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private void rejectRequest(
            HttpServletResponse response,
            int status,
            String message) throws IOException {

        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // Messages are fixed strings, not user-provided input.
        response.getWriter().write(
                "{\"message\":\"" + message + "\"}");
    }
}
