package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.PaymentResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.PaymentService;

@RestController
@RequestMapping("/api/organizer/payments")
public class OrganizerPaymentController {

    private final PaymentService paymentService;

    public OrganizerPaymentController(
            PaymentService paymentService) {

        this.paymentService = paymentService;
    }

    // ============================================================
    // PAYMENT HISTORY
    // ============================================================

    @GetMapping
    public ResponseEntity<List<PaymentResponse>>
    getPaymentHistory(
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                paymentService
                        .getOrganizerPaymentHistory(
                                user.getId())
        );
    }

    // ============================================================
    // APPROVE PAYMENT
    // ============================================================

    @PutMapping("/{paymentId}/approve")
    public ResponseEntity<PaymentResponse>
    approvePayment(
            @PathVariable Long paymentId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                paymentService.approvePayment(
                        user.getId(),
                        paymentId)
        );
    }

    // ============================================================
    // REJECT PAYMENT
    // ============================================================

    @PutMapping("/{paymentId}/reject")
    public ResponseEntity<PaymentResponse>
    rejectPayment(
            @PathVariable Long paymentId,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                paymentService.rejectPayment(
                        user.getId(),
                        paymentId)
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