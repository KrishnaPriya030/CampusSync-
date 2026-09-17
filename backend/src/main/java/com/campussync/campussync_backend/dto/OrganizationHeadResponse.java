package com.campussync.campussync_backend.dto;

public class OrganizationHeadResponse {

    private Long id;
    private Long userId;
    private String name;
    private String email;
    private String phoneNumber;
    private Long organizationId;
    private String organizationName;
    private String designation;
    private String accountStatus;
    private boolean firstLogin;

    public OrganizationHeadResponse(
            Long id,
            Long userId,
            String name,
            String email,
            String phoneNumber,
            Long organizationId,
            String organizationName,
            String designation,
            String accountStatus,
            boolean firstLogin) {

        this.id = id;
        this.userId = userId;
        this.name = name;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.organizationId = organizationId;
        this.organizationName = organizationName;
        this.designation = designation;
        this.accountStatus = accountStatus;
        this.firstLogin = firstLogin;
    }

    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public Long getOrganizationId() {
        return organizationId;
    }

    public String getOrganizationName() {
        return organizationName;
    }

    public String getDesignation() {
        return designation;
    }

    public String getAccountStatus() {
        return accountStatus;
    }

    public boolean isFirstLogin() {
        return firstLogin;
    }
}