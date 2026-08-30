package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;
import com.campussync.campussync_backend.dto.UpdateStudentRequest;
import com.campussync.campussync_backend.dto.StudentListResponse;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.dto.CreateStudentRequest;
import com.campussync.campussync_backend.dto.CreateStudentResponse;
import com.campussync.campussync_backend.entity.Branch;
import com.campussync.campussync_backend.entity.Department;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.enums.StudentStatus;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.repository.BranchRepository;
import com.campussync.campussync_backend.repository.DepartmentRepository;
import com.campussync.campussync_backend.repository.StudentRepository;
import com.campussync.campussync_backend.repository.UserRepository;


@Service
public class StudentManagementService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final DepartmentRepository departmentRepository;
    private final BranchRepository branchRepository;
    private final PasswordEncoder passwordEncoder;

    public StudentManagementService(
            UserRepository userRepository,
            StudentRepository studentRepository,
            DepartmentRepository departmentRepository,
            BranchRepository branchRepository,
            PasswordEncoder passwordEncoder) {

        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.departmentRepository = departmentRepository;
        this.branchRepository = branchRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public CreateStudentResponse createStudent(CreateStudentRequest request) {

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists");
        }

        String temporaryPassword = request.getDateOfBirth()
        .format(java.time.format.DateTimeFormatter.ofPattern("ddMMyyyy"));
        String encodedPassword =
                passwordEncoder.encode(temporaryPassword);

        Department department = departmentRepository
                .findById(request.getDepartmentId())
                .orElseThrow(() ->
                        new RuntimeException("Department not found"));

        Branch branch = branchRepository
                .findById(request.getBranchId())
                .orElseThrow(() ->
                        new RuntimeException("Branch not found"));

        // Make sure the branch belongs to the selected department
        if (!branch.getDepartment().getId()
                .equals(department.getId())) {

            throw new RuntimeException(
                    "Branch does not belong to selected department");
        }

        User user = new User();

        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setPassword(encodedPassword);
        user.setRole(Role.STUDENT);
        user.setStatus(UserStatus.ACTIVE);
        user.setCreatedAt(LocalDateTime.now());
        user.setFirstLogin(true);

        userRepository.save(user);

        Student student = new Student();

        student.setUser(user);
        student.setRegisterNumber(request.getRegisterNumber());
        student.setDateOfBirth(request.getDateOfBirth());
        student.setDepartment(department);
        student.setBranch(branch);
        student.setProgramme(request.getProgramme());
student.setAdmissionYear(request.getAdmissionYear());
        student.setSemester(request.getSemester());
        student.setGraduationYear(request.getGraduationYear());
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
   
public List<StudentListResponse> getAllStudents() {

    return studentRepository.findAll()
            .stream()
            .map(student -> new StudentListResponse(
                    student.getId(),
                    student.getUser().getName(),
                    student.getUser().getEmail(),
                    student.getRegisterNumber(),
                    student.getDepartment().getId(),
                    student.getDepartment().getName(),
                    student.getBranch().getId(),
                    student.getBranch().getName(),
                    student.getProgramme(),
                    student.getAdmissionYear(),
                    student.getSemester(),
                    student.getGraduationYear(),
                    student.isInternal(),
                    student.getStatus().name(),
                    student.getUser().getStatus().name()
            ))
            .toList();
}
public StudentListResponse getStudentById(Long id) {

    Student student = studentRepository.findById(id)
            .orElseThrow(() ->
                    new RuntimeException("Student not found"));

    return new StudentListResponse(
            student.getId(),
            student.getUser().getName(),
            student.getUser().getEmail(),
            student.getRegisterNumber(),
            student.getDepartment().getId(),
            student.getDepartment().getName(),
            student.getBranch().getId(),
            student.getBranch().getName(),
            student.getProgramme(),
            student.getAdmissionYear(),
            student.getSemester(),
            student.getGraduationYear(),
            student.isInternal(),
            student.getStatus().name(),
            student.getUser().getStatus().name()
    );
}
        
    

public StudentListResponse updateStudent(
        Long id,
        UpdateStudentRequest request) {

    Student student = studentRepository.findById(id)
            .orElseThrow(() ->
                    new RuntimeException("Student not found"));

    Department department = departmentRepository
            .findById(request.getDepartmentId())
            .orElseThrow(() ->
                    new RuntimeException("Department not found"));

    Branch branch = branchRepository
            .findById(request.getBranchId())
            .orElseThrow(() ->
                    new RuntimeException("Branch not found"));

    if (!branch.getDepartment().getId()
            .equals(department.getId())) {

        throw new RuntimeException(
                "Branch does not belong to selected department");
    }

    User user = student.getUser();

    // User details
    user.setName(request.getName());
    user.setPhoneNumber(request.getPhoneNumber());

    // Student academic details
    student.setProgramme(request.getProgramme());
    student.setAdmissionYear(request.getAdmissionYear());
    student.setDepartment(department);
    student.setBranch(branch);
    student.setSemester(request.getSemester());
    student.setGraduationYear(request.getGraduationYear());
    student.setInternal(request.isInternal());

    userRepository.save(user);
    studentRepository.save(student);

    return getStudentById(id);
}
public StudentListResponse deactivateStudent(Long id) {

    Student student = studentRepository.findById(id)
            .orElseThrow(() ->
                    new RuntimeException("Student not found"));

    User user = student.getUser();

    user.setStatus(UserStatus.BLOCKED);

    userRepository.save(user);

    return getStudentById(id);
}

public StudentListResponse activateStudent(Long id) {

    Student student = studentRepository.findById(id)
            .orElseThrow(() ->
                    new RuntimeException("Student not found"));

    User user = student.getUser();

    user.setStatus(UserStatus.ACTIVE);
    student.setStatus(StudentStatus.ACTIVE);

    userRepository.save(user);
    studentRepository.save(student);

    return getStudentById(id);
}
}