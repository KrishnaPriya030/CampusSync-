
package com.campussync.campussync_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ChangePasswordRequest {

    @NotBlank(message = "Current password is required")
    private String currentPassword;

    @NotBlank(message = "New password is required")
    @Size(min = 8, max = 128,
          message = "New password must be between 8 and 128 characters")
    private String newPassword;

    @NotBlank(message = "Confirm password is required")
    @Size(max = 128,
          message = "Confirm password must not exceed 128 characters")
    private String confirmPassword;
}
