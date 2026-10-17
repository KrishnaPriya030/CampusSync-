
package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.campussync.campussync_backend.dto.RefundResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.service.RefundService;

@RestController
@RequestMapping("/api/organizer/refunds")
public class OrganizerRefundController {

    private final RefundService refundService;

    public OrganizerRefundController(RefundService refundService) {
        this.refundService = refundService;
    }

    @GetMapping
    public ResponseEntity<List<RefundResponse>> getRefundHistory(
            Authentication authentication) {

        User user = getAuthenticatedOrganizer(authentication);

        return ResponseEntity.ok(
                refundService.getOrganizerRefundHistory(user.getId())
        );
    }

    @PutMapping("/{refundId}/approve")
    public ResponseEntity<RefundResponse> approveRefund(
            @PathVariable Long refundId,
            @RequestParam(required = false, defaultValue = "") String note,
            Authentication authentication) {

        User user = getAuthenticatedOrganizer(authentication);

        return ResponseEntity.ok(
                refundService.approveRefund(user.getId(), refundId, note)
        );
    }

    @PutMapping("/{refundId}/reject")
    public ResponseEntity<RefundResponse> rejectRefund(
            @PathVariable Long refundId,
            @RequestParam(required = false, defaultValue = "") String note,
            Authentication authentication) {

        User user = getAuthenticatedOrganizer(authentication);

        return ResponseEntity.ok(
                refundService.rejectRefund(user.getId(), refundId, note)
        );
    }

    private User getAuthenticatedOrganizer(
            Authentication authentication) {

        if (authentication == null
                || !authentication.isAuthenticated()) {
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

        if (user.getRole() != Role.ORGANIZER) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Only organizers can access these endpoints"
            );
        }

        return user;
    }
}
