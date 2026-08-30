package com.campussync.campussync_backend.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateStudentRequest {

    @NotBlank
    private String name;

    @NotBlank
    @Email
    private String email;

    @NotBlank
    private String phoneNumber;

    @NotBlank
    private String registerNumber;

    @NotNull
    private LocalDate dateOfBirth;

    @NotNull
    private Long departmentId;

    @NotNull
    private Long branchId;

    @NotNull
    private Integer semester;
    @NotBlank
private String programme;

@NotNull
private Integer admissionYear;

    @NotNull
    private Integer graduationYear;
}