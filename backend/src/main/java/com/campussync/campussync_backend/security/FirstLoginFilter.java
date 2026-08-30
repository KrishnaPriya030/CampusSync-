package com.campussync.campussync_backend.security;

import java.io.IOException;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.campussync.campussync_backend.entity.User;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class FirstLoginFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        if (authentication != null
                && authentication.isAuthenticated()
                && authentication.getPrincipal() instanceof User user
                && user.isFirstLogin()) {

            String uri = request.getRequestURI();

            boolean allowed =
                    uri.equals("/api/users/change-password")
                    || uri.startsWith("/api/auth/");

            if (!allowed) {

                response.setStatus(
                        HttpServletResponse.SC_FORBIDDEN);

                response.setContentType("application/json");

                response.getWriter().write(
                        "{\"message\":\"Please change your password before accessing CampusSync.\"}"
                );

                return;
            }
        }

        filterChain.doFilter(request, response);
    }
}