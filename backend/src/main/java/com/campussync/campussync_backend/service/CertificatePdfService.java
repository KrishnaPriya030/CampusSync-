
package com.campussync.campussync_backend.service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.format.DateTimeFormatter;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Service;

import com.campussync.campussync_backend.entity.Certificate;
import com.campussync.campussync_backend.entity.CertificateTemplate;

@Service
public class CertificatePdfService {

    private static final DateTimeFormatter DATE_FORMAT =
            DateTimeFormatter.ofPattern("dd MMMM yyyy");

    private static final String UPLOAD_DIRECTORY =
            "uploads/certificates";

    public String generateAndSaveCertificatePdf(
            Certificate certificate) {

        CertificateTemplate template =
                certificate.getCertificateTemplate();

        if (template == null) {
            throw new RuntimeException(
                    "Certificate template is not configured");
        }

        try {

            byte[] pdfBytes =
                    generateCertificatePdf(certificate);

            Path uploadDirectory =
                    Paths.get(UPLOAD_DIRECTORY);

            Files.createDirectories(uploadDirectory);

            String fileName =
                    certificate.getCertificateNumber()
                            + ".pdf";

            Path filePath =
                    uploadDirectory.resolve(fileName);

            Files.write(
                    filePath,
                    pdfBytes);

            return "/uploads/certificates/"
                    + fileName;

        } catch (IOException e) {

            throw new RuntimeException(
                    "Failed to save certificate PDF",
                    e);
        }
    }

    private byte[] generateCertificatePdf(
            Certificate certificate) {

        CertificateTemplate template =
                certificate.getCertificateTemplate();

        try (PDDocument document =
                     new PDDocument()) {

            PDPage page =
                    new PDPage(PDRectangle.A4);

            document.addPage(page);

            PDRectangle pageSize =
                    page.getMediaBox();

            float width =
                    pageSize.getWidth();

            float height =
                    pageSize.getHeight();

            PDType1Font regularFont =
                    new PDType1Font(
                            Standard14Fonts.FontName.HELVETICA);

            PDType1Font boldFont =
                    new PDType1Font(
                            Standard14Fonts.FontName.HELVETICA_BOLD);

            try (PDPageContentStream content =
                         new PDPageContentStream(
                                 document,
                                 page)) {

                // ====================================================
                // OUTER BORDER
                // ====================================================

                content.setLineWidth(4);

                content.addRect(
                        25,
                        25,
                        width - 50,
                        height - 50);

                content.stroke();

                content.setLineWidth(1);

                content.addRect(
                        35,
                        35,
                        width - 70,
                        height - 70);

                content.stroke();

                // ====================================================
                // ORGANIZATION
                // ====================================================

                drawCenteredText(
                        content,
                        safe(template.getOrganizationName()),
                        boldFont,
                        22,
                        width / 2,
                        height - 90);

                // ====================================================
                // TITLE
                // ====================================================

                drawCenteredText(
                        content,
                        safe(template.getCertificateTitle()),
                        boldFont,
                        28,
                        width / 2,
                        height - 140);

                // ====================================================
                // DESCRIPTION
                // ====================================================

                String description =
                        replacePlaceholders(
                                safe(template.getDescription()),
                                certificate);

                drawCenteredText(
                        content,
                        description,
                        regularFont,
                        14,
                        width / 2,
                        height - 200);

                // ====================================================
                // STUDENT NAME
                // ====================================================

                String studentName =
                        certificate.getStudent()
                                .getUser()
                                .getName();

                drawCenteredText(
                        content,
                        studentName,
                        boldFont,
                        26,
                        width / 2,
                        height - 255);

                // ====================================================
                // STUDENT NAME LINE
                // ====================================================

                float nameWidth =
                        boldFont.getStringWidth(studentName)
                                / 1000
                                * 26;

                content.setLineWidth(1);

                content.moveTo(
                        (width - nameWidth) / 2,
                        height - 265);

                content.lineTo(
                        (width + nameWidth) / 2,
                        height - 265);

                content.stroke();

                // ====================================================
                // EVENT
                // ====================================================

                String eventTitle =
                        certificate.getEvent()
                                .getTitle();

                drawCenteredText(
                        content,
                        "Event: " + eventTitle,
                        regularFont,
                        14,
                        width / 2,
                        height - 315);

                // ====================================================
                // REGISTER NUMBER
                // ====================================================

                String registerNumber =
                        safe(certificate.getStudent()
                                .getRegisterNumber());

                drawCenteredText(
                        content,
                        "Register Number: "
                                + registerNumber,
                        regularFont,
                        12,
                        width / 2,
                        height - 345);

                // ====================================================
                // CERTIFICATE NUMBER
                // ====================================================

                drawCenteredText(
                        content,
                        "Certificate No: "
                                + certificate.getCertificateNumber(),
                        regularFont,
                        11,
                        width / 2,
                        75);

                // ====================================================
                // ISSUE DATE
                // ====================================================

                String issuedDate =
                        certificate.getIssuedAt()
                                .format(DATE_FORMAT);

                drawCenteredText(
                        content,
                        "Issued on: " + issuedDate,
                        regularFont,
                        11,
                        width / 2,
                        55);

                // ====================================================
                // SIGNATURE 1
                // ====================================================

                if (template.getSignature1Name() != null
                        && !template.getSignature1Name().isBlank()) {

                    drawCenteredText(
                            content,
                            template.getSignature1Name(),
                            boldFont,
                            12,
                            150,
                            130);

                    drawCenteredText(
                            content,
                            safe(template.getSignature1Designation()),
                            regularFont,
                            10,
                            150,
                            115);
                }

                // ====================================================
                // SIGNATURE 2
                // ====================================================

                if (template.getSignature2Name() != null
                        && !template.getSignature2Name().isBlank()) {

                    drawCenteredText(
                            content,
                            template.getSignature2Name(),
                            boldFont,
                            12,
                            width - 150,
                            130);

                    drawCenteredText(
                            content,
                            safe(template.getSignature2Designation()),
                            regularFont,
                            10,
                            width - 150,
                            115);
                }
            }

            ByteArrayOutputStream output =
                    new ByteArrayOutputStream();

            document.save(output);

            return output.toByteArray();

        } catch (IOException e) {

            throw new RuntimeException(
                    "Failed to generate certificate PDF",
                    e);
        }
    }

    // ============================================================
    // PLACEHOLDER REPLACEMENT
    // ============================================================

    private String replacePlaceholders(
            String text,
            Certificate certificate) {

        String studentName =
                certificate.getStudent()
                        .getUser()
                        .getName();

        String eventName =
                certificate.getEvent()
                        .getTitle();

        String registerNumber =
                safe(certificate.getStudent()
                        .getRegisterNumber());

        String certificateNumber =
                certificate.getCertificateNumber();

        String issuedDate =
                certificate.getIssuedAt()
                        .format(DATE_FORMAT);

        return text
                .replace("{{studentName}}", studentName)
                .replace("{{eventName}}", eventName)
                .replace("{{registerNumber}}", registerNumber)
                .replace("{{certificateNumber}}", certificateNumber)
                .replace("{{issuedDate}}", issuedDate);
    }

    // ============================================================
    // CENTER TEXT
    // ============================================================

    private void drawCenteredText(
            PDPageContentStream content,
            String text,
            PDType1Font font,
            float fontSize,
            float centerX,
            float y)
            throws IOException {

        if (text == null || text.isBlank()) {
            return;
        }

        float textWidth =
                font.getStringWidth(text)
                        / 1000
                        * fontSize;

        float x =
                centerX - (textWidth / 2);

        content.beginText();

        content.setFont(
                font,
                fontSize);

        content.newLineAtOffset(
                x,
                y);

        content.showText(text);

        content.endText();
    }

    // ============================================================
    // SAFE STRING
    // ============================================================

    private String safe(String value) {

        return value == null
                ? ""
                : value;
    }
}

