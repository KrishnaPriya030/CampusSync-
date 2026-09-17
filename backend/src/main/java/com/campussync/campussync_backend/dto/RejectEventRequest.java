
package com.campussync.campussync_backend.dto;

import jakarta.validation.constraints.NotBlank;

public record RejectEventRequest(

        @NotBlank
        String reason

) {
}

