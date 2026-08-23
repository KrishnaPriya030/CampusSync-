package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.campussync.campussync_backend.enums.StudentStatus;

import com.campussync.campussync_backend.dto.CreateStudentRequest;
import com.campussync.campussync_backend.dto.CreateStudentResponse;
import com.campussync.campussync_backend.entity.Department;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.repository.DepartmentRepository;
import com.campussync.campussync_backend.repository.StudentRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class StudentManagementService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final DepartmentRepository departmentRepository;
    private final PasswordEncoder passwordEncoder;

    public StudentManagementService(
            UserRepository userRepository,
            StudentRepository studentRepository,
            DepartmentRepository departmentRepository,
            PasswordEncoder passwordEncoder) {

        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.departmentRepository = departmentRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public CreateStudentResponse createStudent(CreateStudentRequest request) {

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists");
        }

        String temporaryPassword = "Temp@123";

        String encodedPassword = passwordEncoder.encode(temporaryPassword);

        Department department = departmentRepository
                .findById(request.getDepartmentId())
                .orElseThrow(() ->
                        new RuntimeException("Department not found"));

        User user = new User();

        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setPassword(encodedPassword);
        user.setRole(Role.STUDENT);
        user.setStatus(UserStatus.ACTIVE);
        user.setCreatedAt(LocalDateTime.now());

        // ✅ Correct
        user.setFirstLogin(true);

        userRepository.save(user);

        Student student = new Student();

        student.setUser(user);
        student.setRegisterNumber(request.getRegisterNumber());
        student.setDepartment(department);
        student.setSemester(request.getSemester());
        student.setInternal(true);
        student.setStatus(StudentStatus.ACTIVE);

        studentRepository.save(student);

        return new CreateStudentResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                student.getRegisterNumber(),
                temporaryPassword
        );
    }
}