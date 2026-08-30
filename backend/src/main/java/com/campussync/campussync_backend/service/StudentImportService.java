package com.campussync.campussync_backend.service;

import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import org.apache.poi.ss.usermodel.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.campussync.campussync_backend.dto.BulkStudentImportResponse;
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
public class StudentImportService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final DepartmentRepository departmentRepository;
    private final BranchRepository branchRepository;
    private final PasswordEncoder passwordEncoder;

    public StudentImportService(
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

    public BulkStudentImportResponse importStudents(MultipartFile file) {

        List<String> errors = new ArrayList<>();

        int totalRows = 0;
        int successful = 0;

        try (InputStream inputStream = file.getInputStream();
             Workbook workbook = WorkbookFactory.create(inputStream)) {

            Sheet sheet = workbook.getSheetAt(0);

            for (int rowIndex = 1;
                 rowIndex <= sheet.getLastRowNum();
                 rowIndex++) {

                Row row = sheet.getRow(rowIndex);

                if (row == null || isEmptyRow(row)) {
                    continue;
                }

                totalRows++;

                try {

                    String name =
                            getCellValue(row.getCell(0));

                    String email =
                            getCellValue(row.getCell(1));

                    String phoneNumber =
                            getCellValue(row.getCell(2));

                    String registerNumber =
                            getCellValue(row.getCell(3));

                    LocalDate dateOfBirth =
                            LocalDate.parse(
                                    getCellValue(row.getCell(4)),
                                    DateTimeFormatter.ofPattern("dd/MM/yyyy")
                            );

                    String programme =
                            getCellValue(row.getCell(5));

                    Long departmentId =
                            Long.valueOf(
                                    getCellValue(row.getCell(6))
                            );

                    Long branchId =
                            Long.valueOf(
                                    getCellValue(row.getCell(7))
                            );

                    Integer semester =
                            Integer.valueOf(
                                    getCellValue(row.getCell(8))
                            );

                    Integer admissionYear =
                            Integer.valueOf(
                                    getCellValue(row.getCell(9))
                            );

                    Integer graduationYear =
                            Integer.valueOf(
                                    getCellValue(row.getCell(10))
                            );

                    // Validate required fields
                    if (name.isBlank()
                            || email.isBlank()
                            || phoneNumber.isBlank()
                            || registerNumber.isBlank()
                            || programme.isBlank()) {

                        throw new RuntimeException(
                                "Required field is empty"
                        );
                    }

                    // Check duplicate email
                    if (userRepository.existsByEmail(email)) {

                        throw new RuntimeException(
                                "Email already exists: " + email
                        );
                    }

                    // Find department
                    Department department =
                            departmentRepository.findById(departmentId)
                                    .orElseThrow(() ->
                                            new RuntimeException(
                                                    "Department not found: "
                                                            + departmentId
                                            )
                                    );

                    // Find branch
                    Branch branch =
                            branchRepository.findById(branchId)
                                    .orElseThrow(() ->
                                            new RuntimeException(
                                                    "Branch not found: "
                                                            + branchId
                                            )
                                    );

                    // Validate branch/department relationship
                    if (!branch.getDepartment().getId()
                            .equals(department.getId())) {

                        throw new RuntimeException(
                                "Branch does not belong to department"
                        );
                    }

                    // Initial password = DOB
                    String temporaryPassword =
                            dateOfBirth.format(
                                    DateTimeFormatter.ofPattern("ddMMyyyy")
                            );

                    // Create User
                    User user = new User();

                    user.setName(name);
                    user.setEmail(email);
                    user.setPhoneNumber(phoneNumber);

                    user.setPassword(
                            passwordEncoder.encode(
                                    temporaryPassword
                            )
                    );

                    user.setRole(Role.STUDENT);
                    user.setStatus(UserStatus.ACTIVE);
                    user.setCreatedAt(LocalDateTime.now());
                    user.setFirstLogin(true);

                    userRepository.save(user);

                    // Create Student
                    Student student = new Student();

                    student.setUser(user);
                    student.setRegisterNumber(registerNumber);
                    student.setDateOfBirth(dateOfBirth);
                    student.setProgramme(programme);
                    student.setAdmissionYear(admissionYear);
                    student.setDepartment(department);
                    student.setBranch(branch);
                    student.setSemester(semester);
                    student.setGraduationYear(graduationYear);
                    student.setInternal(true);
                    student.setStatus(StudentStatus.ACTIVE);

                    studentRepository.save(student);

                    successful++;

                } catch (Exception e) {

                    errors.add(
                            "Row " + (rowIndex + 1)
                                    + ": " + e.getMessage()
                    );
                }
            }

        } catch (Exception e) {

            errors.add(
                    "Could not read Excel file: "
                            + e.getMessage()
            );
        }

        return new BulkStudentImportResponse(
                totalRows,
                successful,
                totalRows - successful,
                errors
        );
    }

    private boolean isEmptyRow(Row row) {

        for (int i = 0; i < 11; i++) {

            Cell cell = row.getCell(i);

            if (cell != null
                    && cell.getCellType() != CellType.BLANK
                    && !getCellValue(cell).isBlank()) {

                return false;
            }
        }

        return true;
    }

    private String getCellValue(Cell cell) {

        if (cell == null) {
            return "";
        }

        DataFormatter formatter =
                new DataFormatter();

        return formatter
                .formatCellValue(cell)
                .trim();
    }
}