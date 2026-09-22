
package com.campussync.campussync_backend.service;

import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.campussync.campussync_backend.dto.BulkStudentImportResponse;
import com.campussync.campussync_backend.entity.Department;
import com.campussync.campussync_backend.entity.DepartmentHead;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.repository.DepartmentHeadRepository;
import com.campussync.campussync_backend.repository.DepartmentRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class DepartmentHeadImportService {

    private final UserRepository userRepository;
    private final DepartmentHeadRepository departmentHeadRepository;
    private final DepartmentRepository departmentRepository;
    private final PasswordEncoder passwordEncoder;

    public DepartmentHeadImportService(
            UserRepository userRepository,
            DepartmentHeadRepository departmentHeadRepository,
            DepartmentRepository departmentRepository,
            PasswordEncoder passwordEncoder) {

        this.userRepository = userRepository;
        this.departmentHeadRepository = departmentHeadRepository;
        this.departmentRepository = departmentRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // ============================================================
    // IMPORT DEPARTMENT HEADS
    // ============================================================

    public BulkStudentImportResponse importDepartmentHeads(
            MultipartFile file) {

        int totalRows = 0;
        int successful = 0;
        int failed = 0;

        List<String> errors = new ArrayList<>();

        try (InputStream inputStream = file.getInputStream();
             Workbook workbook =
                     WorkbookFactory.create(inputStream)) {

            Sheet sheet = workbook.getSheetAt(0);

            for (int rowIndex = 1;
                 rowIndex <= sheet.getLastRowNum();
                 rowIndex++) {

                Row row = sheet.getRow(rowIndex);

                if (row == null || isRowEmpty(row)) {
                    continue;
                }

                totalRows++;

                try {

                    /*
                     * Excel columns:
                     *
                     * 0 = Name
                     * 1 = Email
                     * 2 = Phone
                     * 3 = Date of Birth
                     * 4 = Department ID
                     * 5 = Designation
                     */

                    String name =
                            getCellValue(
                                    row.getCell(0));

                    String email =
                            getCellValue(
                                    row.getCell(1));

                    String phoneNumber =
                            getCellValue(
                                    row.getCell(2));

                    String departmentIdValue =
                            getCellValue(
                                    row.getCell(4));

                    String designation =
                            getCellValue(
                                    row.getCell(5));

                    if (name.isBlank()) {
                        throw new RuntimeException(
                                "Name is required");
                    }

                    if (email.isBlank()) {
                        throw new RuntimeException(
                                "Email is required");
                    }

                    if (departmentIdValue.isBlank()) {
                        throw new RuntimeException(
                                "Department ID is required");
                    }

                    if (designation.isBlank()) {
                        throw new RuntimeException(
                                "Designation is required");
                    }

                    if (userRepository.existsByEmail(email)) {
                        throw new RuntimeException(
                                "Email already exists: " + email);
                    }

                    /*
                     * Parse Date of Birth
                     */

                    LocalDate dateOfBirth =
                            parseDateOfBirth(
                                    row.getCell(3));

                    /*
                     * Parse Department ID
                     */

                    Long departmentId;

                    try {

                        departmentId =
                                Long.parseLong(
                                        departmentIdValue);

                    } catch (NumberFormatException e) {

                        throw new RuntimeException(
                                "Invalid department ID: "
                                        + departmentIdValue);
                    }

                    /*
                     * Find Department
                     */

                    Department department =
                            departmentRepository.findById(
                                    departmentId)
                                    .orElseThrow(() ->
                                            new RuntimeException(
                                                    "Department not found: "
                                                            + departmentId));

                    /*
                     * Department must be active
                     */

                    if (department.getActive() == null
                            || !department.getActive()) {

                        throw new RuntimeException(
                                "Department is inactive: "
                                        + departmentId);
                    }

                    /*
                     * Only one Department Head
                     * is allowed per department.
                     */

                    if (departmentHeadRepository
                            .existsByDepartmentId(
                                    departmentId)) {

                        throw new RuntimeException(
                                "This department already has a Department Head: "
                                        + departmentId);
                    }

                    /*
                     * Initial password = Date of Birth
                     *
                     * Example:
                     *
                     * DOB      = 15/08/1998
                     * Password = 15081998
                     *
                     * Password is stored as BCrypt.
                     */

                    String temporaryPassword =
                            dateOfBirth.format(
                                    DateTimeFormatter.ofPattern(
                                            "ddMMyyyy"));

                    /*
                     * Create User
                     */

                    User user = new User();

                    user.setName(name);

                    user.setEmail(email);

                    user.setPhoneNumber(
                            phoneNumber.isBlank()
                                    ? null
                                    : phoneNumber);

                    /*
                     * Store Date of Birth
                     */

                    user.setDateOfBirth(
                            dateOfBirth);

                    user.setPassword(
                            passwordEncoder.encode(
                                    temporaryPassword));

                    user.setRole(
                            Role.DEPARTMENT_HEAD);

                    user.setStatus(
                            UserStatus.ACTIVE);

                    user.setCreatedAt(
                            LocalDateTime.now());

                    /*
                     * Force password change
                     * during first login.
                     */

                    user.setFirstLogin(true);

                    User savedUser =
                            userRepository.save(user);

                    /*
                     * Create Department Head
                     */

                    DepartmentHead head =
                            new DepartmentHead();

                    head.setUser(savedUser);

                    head.setDepartment(
                            department);

                    head.setDesignation(
                            designation);

                    departmentHeadRepository.save(
                            head);

                    successful++;

                } catch (Exception e) {

                    failed++;

                    errors.add(
                            "Row "
                                    + (rowIndex + 1)
                                    + ": "
                                    + e.getMessage());
                }
            }

        } catch (Exception e) {

            errors.add(
                    "Unable to read Excel file: "
                            + e.getMessage());
        }

        return new BulkStudentImportResponse(
                totalRows,
                successful,
                failed,
                errors);
    }

    // ============================================================
    // PARSE DATE OF BIRTH
    // ============================================================

    private LocalDate parseDateOfBirth(Cell cell) {

        if (cell == null) {
            throw new RuntimeException(
                    "Date of Birth is required");
        }

        try {

            /*
             * Case 1:
             * Excel stores the value as a real date.
             */

            if (cell.getCellType() == CellType.NUMERIC
                    && DateUtil.isCellDateFormatted(cell)) {

                return cell
                        .getLocalDateTimeCellValue()
                        .toLocalDate();
            }

            /*
             * Case 2:
             * Excel stores the value as text.
             */

            String value =
                    getCellValue(cell);

            if (value.isBlank()) {
                throw new RuntimeException(
                        "Date of Birth is required");
            }

            DateTimeFormatter formatter =
                    DateTimeFormatter.ofPattern(
                            "dd/MM/yyyy");

            return LocalDate.parse(
                    value,
                    formatter);

        } catch (DateTimeParseException e) {

            throw new RuntimeException(
                    "Invalid Date of Birth. Use dd/MM/yyyy format");

        } catch (RuntimeException e) {

            throw e;

        } catch (Exception e) {

            throw new RuntimeException(
                    "Invalid Date of Birth");
        }
    }

    // ============================================================
    // EXCEL CELL -> STRING
    // ============================================================

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

    // ============================================================
    // CHECK EMPTY ROW
    // ============================================================

    private boolean isRowEmpty(Row row) {

        /*
         * Department Head import has 6 columns.
         */

        for (int i = 0; i < 6; i++) {

            Cell cell =
                    row.getCell(i);

            if (cell != null
                    && !getCellValue(cell).isBlank()) {

                return false;
            }
        }

        return true;
    }
}

