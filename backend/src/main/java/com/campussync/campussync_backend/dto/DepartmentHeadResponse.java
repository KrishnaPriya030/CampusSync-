    package com.campussync.campussync_backend.dto;

    public class DepartmentHeadResponse {

        private Long id;
        private Long userId;
        private String name;
        private String email;
        private String phoneNumber;
        private Long departmentId;
        private String departmentName;
        private String designation;
        private String accountStatus;
        private boolean firstLogin;

        public DepartmentHeadResponse(
                Long id,
                Long userId,
                String name,
                String email,
                String phoneNumber,
                Long departmentId,
                String departmentName,
                String designation,
                String accountStatus,
                boolean firstLogin) {

            this.id = id;
            this.userId = userId;
            this.name = name;
            this.email = email;
            this.phoneNumber = phoneNumber;
            this.departmentId = departmentId;
            this.departmentName = departmentName;
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

        public Long getDepartmentId() {
            return departmentId;
        }

        public String getDepartmentName() {
            return departmentName;
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