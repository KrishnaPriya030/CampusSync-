
package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.RefundRequest;
import com.campussync.campussync_backend.dto.RefundResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.service.RefundService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/student/refunds")
public class StudentRefundController {

    private final RefundService refundService;

    public StudentRefundController(RefundService refundService) {
        this.refundService = refundService;
    }

    @PostMapping("/payment/{paymentId}")
    public ResponseEntity<RefundResponse> requestRefund(
            @PathVariable Long paymentId,
            @Valid @RequestBody RefundRequest request,
            Authentication authentication) {

        User user = getAuthenticatedStudent(authentication);

        return ResponseEntity.ok(
                refundService.requestRefund(
                        user.getId(),
                        paymentId,
                        request
                )
        );
    }

    @GetMapping
    public ResponseEntity<List<RefundResponse>> getRefundHistory(
            Authentication authentication) {

        User user = getAuthenticatedStudent(authentication);

        return ResponseEntity.ok(
                refundService.getStudentRefundHistory(user.getId())
        );
    }

    private User getAuthenticatedStudent(
            Authentication authentication) {

        if (authentication == null
                || !authentication.isAuthenticated()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Authentication required"
            );
        }

        Object principal = authentication.getPrincipal();

        if (!(principal instanceof User user)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid authenticated user"
            );
        }

        if (user.getRole() != Role.STUDENT) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Only students can access these endpoints"
            );
        }

        return user;
    }
}
