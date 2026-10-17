
package com.campussync.campussync_backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.campussync.campussync_backend.dto.PaymentResponse;
import com.campussync.campussync_backend.dto.SubmitPaymentRequest;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.service.PaymentService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/student/payments")
public class StudentPaymentController {

    private final PaymentService paymentService;

    public StudentPaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/{registrationId}")
    public ResponseEntity<PaymentResponse> submitPayment(
            @PathVariable Long registrationId,
            @Valid @RequestBody SubmitPaymentRequest request,
            Authentication authentication) {

        User user = getAuthenticatedStudent(authentication);

        return ResponseEntity.ok(
                paymentService.submitPayment(
                        user.getId(),
                        registrationId,
                        request
                )
        );
    }

    @GetMapping("/{registrationId}")
    public ResponseEntity<PaymentResponse> getPayment(
            @PathVariable Long registrationId,
            Authentication authentication) {

        User user = getAuthenticatedStudent(authentication);

        return ResponseEntity.ok(
                paymentService.getPayment(
                        user.getId(),
                        registrationId
                )
        );
    }

    private User getAuthenticatedStudent(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Authentication required"
            );
        }

        Object principal = authentication.getPrincipal();

        if (!(principal instanceof User user)) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid authenticated user"
            );
        }

        if (user.getRole() != Role.STUDENT) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Only students can access these endpoints"
            );
        }

        return user;
    }
}
