package com.campussync.campussync_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class CreateStudentResponse {

    private Long userId;
    private String name;
    private String email;
    private String registerNumber;
    private String temporaryPassword;
}