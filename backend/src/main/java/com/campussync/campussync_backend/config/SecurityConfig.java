
package com.campussync.campussync_backend.config;

import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

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
    public CorsConfigurationSource corsConfigurationSource() {

        CorsConfiguration configuration = new CorsConfiguration();

        // Development origins. Add your trusted production frontend
        // origin explicitly when deploying.
        configuration.setAllowedOriginPatterns(List.of(
                "http://localhost:*",
                "http://127.0.0.1:*"
        ));

        configuration.setAllowedMethods(List.of(
                "GET",
                "POST",
                "PUT",
                "DELETE",
                "PATCH",
                "OPTIONS"
        ));

        configuration.setAllowedHeaders(List.of(
                "Authorization",
                "Content-Type",
                "Accept",
                "Origin",
                "X-Requested-With"
        ));

        configuration.setExposedHeaders(List.of("Authorization"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();

        source.registerCorsConfiguration("/**", configuration);

        return source;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http) throws Exception {

        http
            .csrf(csrf -> csrf.disable())

            .cors(cors -> cors.configurationSource(
                    corsConfigurationSource()
            ))

            .authorizeHttpRequests(auth -> auth

                // Browser CORS preflight requests
                .requestMatchers(HttpMethod.OPTIONS, "/**")
                .permitAll()

                // Public authentication endpoints
                .requestMatchers("/api/auth/**")
                .permitAll()

                .requestMatchers("/error")
                .permitAll()

                // Certificate PDFs must be downloaded through the
                // authenticated certificate endpoint, which checks
                // that the requested certificate belongs to the student.
                // Keep this rule BEFORE the general uploads rule.
                .requestMatchers("/uploads/certificates/**")
                .denyAll()

                // Other uploads remain public for existing features
                // such as event images, if served from this path.
                .requestMatchers("/uploads/**")
                .permitAll()

                // Admin-only APIs
                .requestMatchers("/api/admin/**")
                .hasRole("ADMIN")

                // Organizer-only APIs
                .requestMatchers("/api/organizer/**")
                .hasRole("ORGANIZER")

                // Department Head APIs
                .requestMatchers("/api/department-head/**")
                .hasRole("DEPARTMENT_HEAD")

                // Organization Head APIs
                .requestMatchers("/api/organization-head/**")
                .hasRole("ORGANIZATION_HEAD")

                // Student-only APIs
                .requestMatchers("/api/student/**")
                .hasRole("STUDENT")

                // Notifications are available to authenticated
                // CampusSync roles. Ownership must also be checked
                // in NotificationService.
                .requestMatchers("/api/notifications/**")
                .hasAnyRole(
                        "ADMIN",
                        "ORGANIZER",
                        "DEPARTMENT_HEAD",
                        "ORGANIZATION_HEAD",
                        "STUDENT"
                )

                // All remaining routes require authentication
                .anyRequest()
                .authenticated()
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
