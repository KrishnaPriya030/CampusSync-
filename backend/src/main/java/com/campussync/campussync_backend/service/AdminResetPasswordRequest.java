
package com.campussync.campussync_backend.dto;

import jakarta.validation.constraints.NotBlank;

public class AdminResetPasswordRequest {

    @NotBlank(message = "New password is required")
    private String newPassword;

    @NotBlank(message = "Confirm password is required")
    private String confirmPassword;

    public AdminResetPasswordRequest() {
    }

    public String getNewPassword() {
        return newPassword;
    }

    public void setNewPassword(String newPassword) {
        this.newPassword = newPassword;
    }

    public String getConfirmPassword() {
        return confirmPassword;
    }

    public void setConfirmPassword(String confirmPassword) {
        this.confirmPassword = confirmPassword;
    }
}
