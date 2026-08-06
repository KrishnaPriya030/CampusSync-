package com.campussync.campussync_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.campussync.campussync_backend.dto.UserProfileResponse;
import com.campussync.campussync_backend.service.UserService;
import com.campussync.campussync_backend.dto.ChangePasswordRequest;
import org.springframework.web.bind.annotation.PutMapping;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getCurrentUser() {

        UserProfileResponse response =
                userService.getCurrentUser();

        return ResponseEntity.ok(response);
    }
    @PutMapping("/change-password")
public ResponseEntity<String> changePassword(
        @Valid @RequestBody ChangePasswordRequest request) {

    userService.changePassword(request);

    return ResponseEntity.ok("Password changed successfully");
}
}