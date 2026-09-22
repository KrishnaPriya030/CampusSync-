
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
import com.campussync.campussync_backend.entity.Organization;
import com.campussync.campussync_backend.entity.OrganizationHead;
import com.campussync.campussync_backend.entity.User;
import com.campussync.campussync_backend.enums.Role;
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.repository.OrganizationHeadRepository;
import com.campussync.campussync_backend.repository.OrganizationRepository;
import com.campussync.campussync_backend.repository.UserRepository;

@Service
public class OrganizationHeadImportService {

    private final UserRepository userRepository;
    private final OrganizationHeadRepository organizationHeadRepository;
    private final OrganizationRepository organizationRepository;
    private final PasswordEncoder passwordEncoder;

    public OrganizationHeadImportService(
            UserRepository userRepository,
            OrganizationHeadRepository organizationHeadRepository,
            OrganizationRepository organizationRepository,
            PasswordEncoder passwordEncoder) {

        this.userRepository = userRepository;
        this.organizationHeadRepository = organizationHeadRepository;
        this.organizationRepository = organizationRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // ============================================================
    // IMPORT ORGANIZATION HEADS
    // ============================================================

    public BulkStudentImportResponse importOrganizationHeads(
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
                     * Parse Date of Birth
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
                     * Find Organization
                     */

                    Organization organization =
                            organizationRepository.findById(
                                    organizationId)
                                    .orElseThrow(() ->
                                            new RuntimeException(
                                                    "Organization not found: "
                                                            + organizationId));

                    /*
                     * Organization must be active
                     */

                    if (!organization.isActive()) {

                        throw new RuntimeException(
                                "Organization is inactive: "
                                        + organizationId);
                    }

                    /*
                     * Only one Organization Head
                     * is allowed per organization.
                     */

                    if (organizationHeadRepository
                            .existsByOrganizationId(
                                    organizationId)) {

                        throw new RuntimeException(
                                "This organization already has an Organization Head: "
                                        + organizationId);
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
                            Role.ORGANIZATION_HEAD);

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
                     * Create Organization Head
                     */

                    OrganizationHead organizationHead =
                            new OrganizationHead();

                    organizationHead.setUser(savedUser);

                    organizationHead.setOrganization(
                            organization);

                    organizationHead.setDesignation(
                            designation);

                    organizationHeadRepository.save(
                            organizationHead);

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
         * Organization Head import has 6 columns.
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

