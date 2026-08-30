package com.campussync.campussync_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateStudentRequest {

    @NotBlank
    private String name;

    private String phoneNumber;

    @NotBlank
    private String programme;

    @NotNull
    private Integer admissionYear;

    @NotNull
    private Long departmentId;

    @NotNull
    private Long branchId;

    @NotNull
    private Integer semester;

    @NotNull
    private Integer graduationYear;

    private boolean internal;
}