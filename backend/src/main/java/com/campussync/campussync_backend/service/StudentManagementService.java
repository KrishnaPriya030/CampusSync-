
package com.campussync.campussync_backend.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.campussync.campussync_backend.dto.CreateStudentRequest;
import com.campussync.campussync_backend.dto.CreateStudentResponse;
import com.campussync.campussync_backend.dto.StudentListResponse;
import com.campussync.campussync_backend.dto.UpdateStudentRequest;
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

    private static final DateTimeFormatter INITIAL_PASSWORD_FORMAT =
            DateTimeFormatter.ofPattern("ddMMyyyy");

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

    // CREATE STUDENT

    @Transactional
    public CreateStudentResponse createStudent(CreateStudentRequest request) {

        if (request == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Student details are required");
        }

        validateAcademicDetails(
                request.getAdmissionYear(),
                request.getGraduationYear(),
                request.getSemester());

        if (request.getDateOfBirth() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Date of birth is required");
        }

        String email = request.getEmail() == null
                ? ""
                : request.getEmail().trim();

        String registerNumber = request.getRegisterNumber() == null
                ? ""
                : request.getRegisterNumber().trim();

        if (email.isBlank() || registerNumber.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Email and registration number are required");
        }

        if (userRepository.existsByEmail(email)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Email already exists");
        }

        if (studentRepository.existsByRegisterNumber(registerNumber)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Registration number already exists");
        }

        Department department = departmentRepository
                .findById(request.getDepartmentId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Department not found"));

        Branch branch = branchRepository
                .findById(request.getBranchId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Branch not found"));

        validateBranchDepartment(branch, department);

        // College policy: DOB formatted as ddMMyyyy is the initial password.
        // Store only its encoded form; require a password change at first login.
        String initialPassword = request.getDateOfBirth()
                .format(INITIAL_PASSWORD_FORMAT);

        User user = new User();
        user.setName(request.getName());
        user.setEmail(email);
        user.setPhoneNumber(request.getPhoneNumber());
        user.setPassword(passwordEncoder.encode(initialPassword));
        user.setRole(Role.STUDENT);
        user.setStatus(UserStatus.ACTIVE);
        user.setCreatedAt(LocalDateTime.now());
        user.setFirstLogin(true);

        user = userRepository.save(user);

        Student student = new Student();
        student.setUser(user);
        student.setRegisterNumber(registerNumber);
        student.setDateOfBirth(request.getDateOfBirth());
        student.setDepartment(department);
        student.setBranch(branch);
        student.setProgramme(request.getProgramme());
        student.setAdmissionYear(request.getAdmissionYear());
        student.setSemester(request.getSemester());
        student.setGraduationYear(request.getGraduationYear());
        student.setInternal(true);
        student.setStatus(StudentStatus.ACTIVE);

        student = studentRepository.save(student);

        // The initial password is returned only for the administrator's
        // initial-credential workflow. Never log this value.
        return new CreateStudentResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                student.getRegisterNumber(),
                initialPassword);
    }

    // GET ALL STUDENTS

    @Transactional(readOnly = true)
    public List<StudentListResponse> getAllStudents() {
        return studentRepository.findAll()
                .stream()
                .map(this::toStudentListResponse)
                .toList();
    }

    // GET STUDENT BY ID

    @Transactional(readOnly = true)
    public StudentListResponse getStudentById(Long id) {

        if (id == null || id <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Invalid student ID");
        }

        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Student not found"));

        return toStudentListResponse(student);
    }

    // UPDATE STUDENT

    @Transactional
    public StudentListResponse updateStudent(
            Long id,
            UpdateStudentRequest request) {

        if (id == null || id <= 0 || request == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Valid student ID and update details are required");
        }

        validateAcademicDetails(
                request.getAdmissionYear(),
                request.getGraduationYear(),
                request.getSemester());

        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Student not found"));

        Department department = departmentRepository
                .findById(request.getDepartmentId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Department not found"));

        Branch branch = branchRepository
                .findById(request.getBranchId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Branch not found"));

        validateBranchDepartment(branch, department);

        User user = student.getUser();

        user.setName(request.getName());
        user.setPhoneNumber(request.getPhoneNumber());

        student.setProgramme(request.getProgramme());
        student.setAdmissionYear(request.getAdmissionYear());
        student.setDepartment(department);
        student.setBranch(branch);
        student.setSemester(request.getSemester());
        student.setGraduationYear(request.getGraduationYear());
        student.setInternal(request.isInternal());

        userRepository.save(user);
        studentRepository.save(student);

        return toStudentListResponse(student);
    }

    // DEACTIVATE STUDENT ACCOUNT

    @Transactional
    public StudentListResponse deactivateStudent(Long id) {

        Student student = findStudentOrThrow(id);

        // Block login access without changing the student's academic status.
        // Account status and academic status represent different concepts.
        User user = student.getUser();
        user.setStatus(UserStatus.BLOCKED);
        userRepository.save(user);

        return toStudentListResponse(student);
    }

    // ACTIVATE STUDENT ACCOUNT

    @Transactional
    public StudentListResponse activateStudent(Long id) {

        Student student = findStudentOrThrow(id);

        User user = student.getUser();
        user.setStatus(UserStatus.ACTIVE);
        student.setStatus(StudentStatus.ACTIVE);

        userRepository.save(user);
        studentRepository.save(student);

        return toStudentListResponse(student);
    }

    // SHARED VALIDATION

    private Student findStudentOrThrow(Long id) {

        if (id == null || id <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Invalid student ID");
        }

        return studentRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Student not found"));
    }

    private void validateBranchDepartment(
            Branch branch,
            Department department) {

        if (branch.getDepartment() == null
                || branch.getDepartment().getId() == null
                || !branch.getDepartment().getId()
                        .equals(department.getId())) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Branch does not belong to the selected department");
        }
    }

    private void validateAcademicDetails(
            Integer admissionYear,
            Integer graduationYear,
            Integer semester) {

        int currentYear = LocalDate.now().getYear();

        if (admissionYear == null
                || admissionYear < 1900
                || admissionYear > currentYear + 1) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Invalid admission year");
        }

        if (semester == null || semester < 1) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Semester must be at least 1");
        }

        if (graduationYear != null
                && graduationYear < admissionYear) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Graduation year cannot be before admission year");
        }
    }

    // MAP ENTITY TO RESPONSE

    private StudentListResponse toStudentListResponse(Student student) {

        return new StudentListResponse(
                student.getId(),
                student.getUser().getName(),
                student.getUser().getEmail(),
                student.getUser().getPhoneNumber(),
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
                student.getUser().getStatus().name());
    }
}
