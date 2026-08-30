package com.campussync.campussync_backend.entity;

import com.campussync.campussync_backend.enums.StudentStatus;

import jakarta.persistence.*;

import jakarta.validation.constraints.NotBlank;
import java.time.LocalDate;
import jakarta.validation.constraints.NotNull;

import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "students")
@Getter
@Setter
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @NotBlank
    private String registerNumber;

    @ManyToOne
    @JoinColumn(name = "department_id", nullable = false)
    private Department department;

    @ManyToOne
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @NotNull
    private Integer semester;

    private boolean internal;

    private String collegeName;
    @NotBlank
private String programme;

@NotNull
private Integer admissionYear;

    private Integer graduationYear;


    @NotNull
    @Enumerated(EnumType.STRING)
    private StudentStatus status;
    private LocalDate dateOfBirth;
}