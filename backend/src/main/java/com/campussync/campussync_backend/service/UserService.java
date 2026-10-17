
package com.campussync.campussync_backend.service;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.campussync.campussync_backend.dto.ChangePasswordRequest;
import com.campussync.campussync_backend.dto.UserProfileResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.exception.InvalidCredentialsException;
import com.campussync.campussync_backend.exception.PasswordMismatchException;
import com.campussync.campussync_backend.repository.UserRepository;

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

    // GET PROFILE OF THE CURRENTLY AUTHENTICATED USER
    public UserProfileResponse getCurrentUser() {

        User user = getAuthenticatedUser();

        return new UserProfileResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole().name()
        );
    }

    // CHANGE PASSWORD OF THE CURRENTLY AUTHENTICATED USER
    public void changePassword(ChangePasswordRequest request) {

        if (request == null
                || request.getCurrentPassword() == null
                || request.getNewPassword() == null
                || request.getConfirmPassword() == null) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "All password fields are required"
            );
        }

        User user = getAuthenticatedUser();

        // Verify the current password.
        if (!passwordEncoder.matches(
                request.getCurrentPassword(),
                user.getPassword())) {

            throw new InvalidCredentialsException(
                    "Current password is incorrect"
            );
        }

        // Verify that the new password and confirmation match.
        if (!request.getNewPassword().equals(
                request.getConfirmPassword())) {

            throw new PasswordMismatchException(
                    "New password and confirm password do not match"
            );
        }

        // Store only the encoded password.
        user.setPassword(
                passwordEncoder.encode(
                        request.getNewPassword()
                )
        );

        // Allow the user to continue beyond the first-login restriction.
        user.setFirstLogin(false);

        userRepository.save(user);
    }

    // ADMIN RESET PASSWORD
    public void resetPasswordByAdmin(
            Long userId,
            String newPassword) {

        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid user ID"
            );
        }

        if (newPassword == null || newPassword.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "New password is required"
            );
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "User not found"
                        )
                );

        user.setPassword(
                passwordEncoder.encode(newPassword)
        );

        // Force the user to change the temporary password
        // after logging in.
        user.setFirstLogin(true);

        userRepository.save(user);
    }

    // GET THE AUTHENTICATED USER SAFELY
    private User getAuthenticatedUser() {

        Authentication authentication =
                SecurityContextHolder.getContext()
                        .getAuthentication();

        if (authentication == null
                || !authentication.isAuthenticated()) {

            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Authentication required"
            );
        }

        Object principal = authentication.getPrincipal();

        if (!(principal instanceof User)) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid authenticated user"
            );
        }

        return (User) principal;
    }
}
