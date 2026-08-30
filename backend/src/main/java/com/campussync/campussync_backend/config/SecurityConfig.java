package com.campussync.campussync_backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import com.campussync.campussync_backend.security.FirstLoginFilter;
import com.campussync.campussync_backend.security.JwtAuthenticationFilter;

@Configuration
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final FirstLoginFilter firstLoginFilter;

    public SecurityConfig(
            JwtAuthenticationFilter jwtAuthenticationFilter,
            FirstLoginFilter firstLoginFilter) {

        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.firstLoginFilter = firstLoginFilter;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http) throws Exception {

        http
            .csrf(csrf -> csrf.disable())

            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/organizer/**").hasRole("ORGANIZER")
                .requestMatchers("/api/student/**").hasRole("STUDENT")
                .anyRequest().authenticated()
            )

            .sessionManagement(session -> session
                .sessionCreationPolicy(
                    SessionCreationPolicy.STATELESS
                )
            )

            .addFilterBefore(
                jwtAuthenticationFilter,
                UsernamePasswordAuthenticationFilter.class
            )

            .addFilterAfter(
                firstLoginFilter,
                JwtAuthenticationFilter.class
            );

        return http.build();
    }
}