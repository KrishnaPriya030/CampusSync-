package com.campussync.campussync_backend.dto;

public class CreateOrganizationHeadResponse {

    private Long userId;
    private Long organizationHeadId;
    private String name;
    private String email;
    private String activationLink;
    private String organizationName;
    private String designation;

    public CreateOrganizationHeadResponse(
            Long userId,
            Long organizationHeadId,
            String name,
            String email,
            String activationLink,
            String organizationName,
            String designation) {

        this.userId = userId;
        this.organizationHeadId = organizationHeadId;
        this.name = name;
        this.email = email;
        this.activationLink = activationLink;
        this.organizationName = organizationName;
        this.designation = designation;
    }

    public Long getUserId() {
        return userId;
    }

    public Long getOrganizationHeadId() {
        return organizationHeadId;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public String getActivationLink() {
        return activationLink;
    }

    public String getOrganizationName() {
        return organizationName;
    }

    public String getDesignation() {
        return designation;
    }
}
