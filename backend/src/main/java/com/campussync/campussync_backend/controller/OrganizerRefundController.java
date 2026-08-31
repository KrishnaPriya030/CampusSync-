package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import com.campussync.campussync_backend.dto.RefundResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.service.RefundService;

@RestController
@RequestMapping("/api/organizer/refunds")
public class OrganizerRefundController {

    private final RefundService refundService;

    public OrganizerRefundController(
            RefundService refundService) {

        this.refundService = refundService;
    }

    @GetMapping
    public ResponseEntity<List<RefundResponse>>
    getRefundHistory(
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                refundService
                        .getOrganizerRefundHistory(
                                user.getId())
        );
    }

    @PutMapping("/{refundId}/approve")
    public ResponseEntity<RefundResponse>
    approveRefund(
            @PathVariable Long refundId,
            @RequestParam(
                    required = false,
                    defaultValue = "")
            String note,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                refundService.approveRefund(
                        user.getId(),
                        refundId,
                        note)
        );
    }

    @PutMapping("/{refundId}/reject")
    public ResponseEntity<RefundResponse>
    rejectRefund(
            @PathVariable Long refundId,
            @RequestParam(
                    required = false,
                    defaultValue = "")
            String note,
            Authentication authentication) {

        User user =
                getAuthenticatedUser(authentication);

        return ResponseEntity.ok(
                refundService.rejectRefund(
                        user.getId(),
                        refundId,
                        note)
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