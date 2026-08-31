package com.campussync.campussync_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.PaymentResponse;
import com.campussync.campussync_backend.dto.SubmitPaymentRequest;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.PaymentService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/student/payments")
public class StudentPaymentController {

    private final PaymentService paymentService;

    public StudentPaymentController(
            PaymentService paymentService) {

        this.paymentService = paymentService;
    }

    @PostMapping("/{registrationId}")
    public ResponseEntity<PaymentResponse> submitPayment(
            @PathVariable Long registrationId,
            @Valid @RequestBody SubmitPaymentRequest request,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                paymentService.submitPayment(
                        user.getId(),
                        registrationId,
                        request)
        );
    }

    @GetMapping("/{registrationId}")
    public ResponseEntity<PaymentResponse> getPayment(
            @PathVariable Long registrationId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                paymentService.getPayment(
                        user.getId(),
                        registrationId)
        );
    }

    private User getAuthenticatedUser(
            Authentication authentication) {

        if (authentication == null ||
                !authentication.isAuthenticated()) {

            throw new RuntimeException(
                    "Authentication required");
        }

        Object principal =
                authentication.getPrincipal();

        if (!(principal instanceof User)) {

            throw new RuntimeException(
                    "Invalid authenticated user");
        }

        return (User) principal;
    }
}