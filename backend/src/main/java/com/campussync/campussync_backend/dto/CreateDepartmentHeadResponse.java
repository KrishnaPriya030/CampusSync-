package com.campussync.campussync_backend.dto;

public class CreateDepartmentHeadResponse {

    private Long userId;
    private Long departmentHeadId;
    private String name;
    private String email;
    private String activationLink;
    private String departmentName;
    private String designation;

    public CreateDepartmentHeadResponse(
            Long userId,
            Long departmentHeadId,
            String name,
            String email,
            String activationLink,
            String departmentName,
            String designation) {

        this.userId = userId;
        this.departmentHeadId = departmentHeadId;
        this.name = name;
        this.email = email;
        this.activationLink = activationLink;
        this.departmentName = departmentName;
        this.designation = designation;
    }

    public Long getUserId() {
        return userId;
    }

    public Long getDepartmentHeadId() {
        return departmentHeadId;
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

    public String getDepartmentName() {
        return departmentName;
    }

    public String getDesignation() {
        return designation;
    }
}