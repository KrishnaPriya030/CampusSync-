package com.campussync.campussync_backend.controller;

import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import com.campussync.campussync_backend.dto.PaymentResponse;
import com.campussync.campussync_backend.dto.RefundResponse;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.service.HeadFinanceService;

@RestController
@RequestMapping("/api/organization-head/finance")
public class OrganizationHeadFinanceController {
    private final HeadFinanceService service;
    public OrganizationHeadFinanceController(HeadFinanceService service) { this.service = service; }

    @GetMapping("/payments")
    public ResponseEntity<List<PaymentResponse>> payments(Authentication auth) {
        User user = requireHead(auth);
        return ResponseEntity.ok(service.getOrganizationPayments(user.getId()));
    }

    @GetMapping("/refunds")
    public ResponseEntity<List<RefundResponse>> refunds(Authentication auth) {
        User user = requireHead(auth);
        return ResponseEntity.ok(service.getOrganizationRefunds(user.getId()));
    }

    private User requireHead(Authentication auth) {
        if (auth == null || !auth.isAuthenticated())
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authentication required");
        if (!(auth.getPrincipal() instanceof User user))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid authenticated user");
        if (user.getRole() != Role.ORGANIZATION_HEAD)
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Organization Head access required");
        return user;
    }
}
