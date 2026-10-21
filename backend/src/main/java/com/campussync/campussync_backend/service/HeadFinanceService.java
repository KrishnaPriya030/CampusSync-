package com.campussync.campussync_backend.service;

import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.campussync.campussync_backend.dto.PaymentResponse;
import com.campussync.campussync_backend.dto.RefundResponse;
import com.campussync.campussync_backend.entity.*;
import com.campussync.campussync_backend.enums.EventScope;
import com.campussync.campussync_backend.repository.*;

@Service
public class HeadFinanceService {
    private final PaymentRepository payments;
    private final RefundRepository refunds;
    private final DepartmentHeadRepository departmentHeads;
    private final OrganizationHeadRepository organizationHeads;

    public HeadFinanceService(PaymentRepository payments, RefundRepository refunds,
            DepartmentHeadRepository departmentHeads, OrganizationHeadRepository organizationHeads) {
        this.payments = payments;
        this.refunds = refunds;
        this.departmentHeads = departmentHeads;
        this.organizationHeads = organizationHeads;
    }

    @Transactional(readOnly = true)
    public List<PaymentResponse> getDepartmentPayments(Long userId) {
        DepartmentHead head = departmentHeads.findByUserId(userId)
                .orElseThrow(() -> new IllegalStateException("Department Head profile not found"));
        if (head.getDepartment() == null) throw new IllegalStateException("Department Head has no department");
        return payments.findDepartmentHeadPayments(head.getDepartment().getId(), EventScope.DEPARTMENT)
                .stream().map(this::paymentResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<RefundResponse> getDepartmentRefunds(Long userId) {
        DepartmentHead head = departmentHeads.findByUserId(userId)
                .orElseThrow(() -> new IllegalStateException("Department Head profile not found"));
        if (head.getDepartment() == null) throw new IllegalStateException("Department Head has no department");
        return refunds.findDepartmentHeadRefunds(head.getDepartment().getId(), EventScope.DEPARTMENT)
                .stream().map(this::refundResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<PaymentResponse> getOrganizationPayments(Long userId) {
        OrganizationHead head = organizationHeads.findByUserId(userId)
                .orElseThrow(() -> new IllegalStateException("Organization Head profile not found"));
        if (head.getOrganization() == null) throw new IllegalStateException("Organization Head has no organization");
        return payments.findOrganizationHeadPayments(head.getOrganization().getId(), EventScope.ORGANIZATION)
                .stream().map(this::paymentResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<RefundResponse> getOrganizationRefunds(Long userId) {
        OrganizationHead head = organizationHeads.findByUserId(userId)
                .orElseThrow(() -> new IllegalStateException("Organization Head profile not found"));
        if (head.getOrganization() == null) throw new IllegalStateException("Organization Head has no organization");
        return refunds.findOrganizationHeadRefunds(head.getOrganization().getId(), EventScope.ORGANIZATION)
                .stream().map(this::refundResponse).toList();
    }

    private PaymentResponse paymentResponse(Payment p) {
        EventRegistration r = p.getRegistration();
        Student s = r.getStudent();
        User u = s.getUser();
        return new PaymentResponse(p.getId(), r.getId(), r.getEvent().getId(), s.getId(),
                u.getName(), u.getEmail(), p.getAmount(), p.getStatus(),
                p.getPaymentReference(), p.getCreatedAt(), p.getPaidAt());
    }

    private RefundResponse refundResponse(Refund r) {
        Payment p = r.getPayment();
        EventRegistration registration = p.getRegistration();
        Student s = registration.getStudent();
        return new RefundResponse(r.getId(), p.getId(), registration.getId(),
                registration.getEvent().getId(), s.getId(), s.getUser().getName(),
                s.getUser().getEmail(), r.getAmount(), r.getReason(), r.getStatus(),
                r.getRequestedAt(), r.getProcessedAt(), r.getProcessingNote());
    }
}
