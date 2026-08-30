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

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    public JwtAuthenticationFilter(
            JwtService jwtService,
            UserRepository userRepository) {

        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        System.out.println("\n================ JWT FILTER ================");
        System.out.println("Request URI : " + request.getRequestURI());

        String authHeader = request.getHeader("Authorization");

        System.out.println("Authorization Header : " + authHeader);

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {

            System.out.println("No Bearer Token Found");
            System.out.println("============================================\n");

            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);

        try {

            String email = jwtService.extractEmail(token);

            System.out.println("JWT Email : " + email);

            if (email != null
                    && SecurityContextHolder.getContext()
                            .getAuthentication() == null) {

                User user = userRepository.findByEmail(email)
                        .orElse(null);

                if (user == null) {

                    System.out.println("User NOT Found");

                } else {

                    System.out.println(
                            "User Found : " + user.getEmail()
                    );

                    boolean valid =
                            jwtService.isTokenValid(
                                    token,
                                    user.getEmail()
                            );

                    System.out.println(
                            "Token Valid : " + valid
                    );

                    if (valid) {

                        System.out.println(
                                "Role : " + user.getRole()
                        );

                        System.out.println(
                                "Account Status : " + user.getStatus()
                        );

                        if (user.getStatus() != UserStatus.ACTIVE) {

                            System.out.println(
                                    "Account is not active. "
                                    + "Authentication rejected."
                            );

                        } else {

                            UsernamePasswordAuthenticationToken authentication =
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
                                    .setAuthentication(authentication);

                            System.out.println(
                                    "Authentication Added Successfully"
                            );
                        }
                    }
                }
            }

        } catch (Exception e) {

            System.out.println("JWT Exception");
            e.printStackTrace();
        }

        System.out.println(
                "============================================\n"
        );

        filterChain.doFilter(request, response);
    }
}