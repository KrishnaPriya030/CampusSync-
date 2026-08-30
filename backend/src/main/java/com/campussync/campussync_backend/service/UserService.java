package com.campussync.campussync_backend.service;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.dto.ChangePasswordRequest;
import com.campussync.campussync_backend.dto.UserProfileResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.exception.InvalidCredentialsException;
import com.campussync.campussync_backend.exception.PasswordMismatchException;
import com.campussync.campussync_backend.repository.UserRepository;

import org.springframework.security.crypto.password.PasswordEncoder;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder) {

        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public UserProfileResponse getCurrentUser() {

        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        User user = (User) authentication.getPrincipal();

        return new UserProfileResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole().name()
        );
    }

    public void changePassword(ChangePasswordRequest request) {

        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        User user = (User) authentication.getPrincipal();

        if (!passwordEncoder.matches(
                request.getCurrentPassword(),
                user.getPassword())) {

            throw new InvalidCredentialsException(
                    "Current password is incorrect"
            );
        }

        if (!request.getNewPassword().equals(
                request.getConfirmPassword())) {

            throw new PasswordMismatchException(
                    "New password and confirm password do not match"
            );
        }

        user.setPassword(
                passwordEncoder.encode(
                        request.getNewPassword()
                )
        );

        user.setFirstLogin(false);

        System.out.println(
                "BEFORE SAVE - firstLogin = "
                + user.isFirstLogin()
        );

        userRepository.save(user);

        System.out.println(
                "AFTER SAVE - firstLogin = "
                + user.isFirstLogin()
        );
    }
}