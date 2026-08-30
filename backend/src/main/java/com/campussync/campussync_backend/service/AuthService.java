package com.campussync.campussync_backend.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.dto.LoginRequest;
import com.campussync.campussync_backend.dto.LoginResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.exception.AccountNotActiveException;
import com.campussync.campussync_backend.exception.InvalidCredentialsException;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService) {

        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public LoginResponse login(LoginRequest request) {

        System.out.println("========== LOGIN DEBUG ==========");
        System.out.println(
                "Request email: [" + request.getEmail() + "]"
        );

        User user = userRepository
                .findByEmail(request.getEmail())
                .orElseThrow(() -> {

                    System.out.println("USER NOT FOUND");

                    return new InvalidCredentialsException(
                            "Invalid email or password"
                    );
                });

        System.out.println("USER FOUND");
        System.out.println(
                "User ID: " + user.getId()
        );
        System.out.println(
                "User email: [" + user.getEmail() + "]"
        );
        System.out.println(
                "User role: " + user.getRole()
        );
        System.out.println(
                "User status: " + user.getStatus()
        );
        System.out.println(
                "First login: " + user.isFirstLogin()
        );

        boolean passwordMatches =
                passwordEncoder.matches(
                        request.getPassword(),
                        user.getPassword()
                );

        System.out.println(
                "PASSWORD MATCH: " + passwordMatches
        );

        if (user.getStatus() != UserStatus.ACTIVE) {

            System.out.println(
                    "ACCOUNT NOT ACTIVE"
            );

            throw new AccountNotActiveException(
                    "Account is not active"
            );
        }

        if (!passwordMatches) {

            System.out.println(
                    "PASSWORD FAILED"
            );

            throw new InvalidCredentialsException(
                    "Invalid email or password"
            );
        }

        String token = jwtService.generateToken(
                user.getEmail(),
                user.getRole().name()
        );

        System.out.println(
                "JWT GENERATED SUCCESSFULLY"
        );
        System.out.println(
                "================================"
        );

        return new LoginResponse(
                token,
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole().name(),
                user.isFirstLogin()
        );
    }
}