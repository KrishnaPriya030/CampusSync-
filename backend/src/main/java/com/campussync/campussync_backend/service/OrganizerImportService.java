
package com.campussync.campussync_backend.service;

import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

import org.apache.poi.ss.usermodel.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.campussync.campussync_backend.dto.BulkStudentImportResponse;
import com.campussync.campussync_backend.entity.Organizer;
import com.campussync.campussync_backend.entity.Organization;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.repository.OrganizerRepository;
import com.campussync.campussync_backend.repository.OrganizationRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class OrganizerImportService {

    private final UserRepository userRepository;
    private final OrganizerRepository organizerRepository;
    private final OrganizationRepository organizationRepository;
    private final PasswordEncoder passwordEncoder;

    public OrganizerImportService(
            UserRepository userRepository,
            OrganizerRepository organizerRepository,
            OrganizationRepository organizationRepository,
            PasswordEncoder passwordEncoder) {

        this.userRepository = userRepository;
        this.organizerRepository = organizerRepository;
        this.organizationRepository = organizationRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public BulkStudentImportResponse importOrganizers(
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
                     * 4 = Organization ID
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

                    String organizationIdValue =
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

                    if (organizationIdValue.isBlank()) {
                        throw new RuntimeException(
                                "Organization ID is required");
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
                     * Parse Date of Birth.
                     *
                     * Supports:
                     * 1. Excel date cell
                     * 2. Text date in dd/MM/yyyy format
                     */

                    LocalDate dateOfBirth =
                            parseDateOfBirth(
                                    row.getCell(3));

                    /*
                     * Parse Organization ID
                     */

                    Long organizationId;

                    try {

                        organizationId =
                                Long.parseLong(
                                        organizationIdValue);

                    } catch (NumberFormatException e) {

                        throw new RuntimeException(
                                "Invalid organization ID: "
                                        + organizationIdValue);
                    }

                    /*
                     * Find organization
                     */

                    Organization organization =
                            organizationRepository.findById(
                                    organizationId)
                                    .orElseThrow(() ->
                                            new RuntimeException(
                                                    "Organization not found: "
                                                            + organizationId));

                    /*
                     * Initial password = Date of Birth
                     *
                     * Example:
                     *
                     * DOB      = 15/08/2000
                     * Password = 15082000
                     *
                     * Password is stored as BCrypt hash.
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

                    user.setPassword(
                            passwordEncoder.encode(
                                    temporaryPassword));

                    user.setRole(
                            Role.ORGANIZER);

                    user.setStatus(
                            UserStatus.ACTIVE);

                    user.setCreatedAt(
                            LocalDateTime.now());

                    /*
                     * Organizer must change password
                     * during first login.
                     */

                    user.setFirstLogin(true);

                    User savedUser =
                            userRepository.save(user);

                    /*
                     * Create Organizer
                     */

                    Organizer organizer =
                            new Organizer();

                    organizer.setUser(savedUser);

                    organizer.setOrganization(
                            organization);

                    organizer.setDesignation(
                            designation);

                    organizerRepository.save(
                            organizer);

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

    /*
     * Parse Organizer Date of Birth
     *
     * Supports both:
     *
     * Excel date cell:
     * 15/08/2000
     *
     * Text cell:
     * "15/08/2000"
     */
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

    /*
     * Convert Excel cell to String
     */

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

    /*
     * Check whether the entire row is empty.
     *
     * Organizer import has 6 columns.
     */

    private boolean isRowEmpty(Row row) {

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

