
package com.campussync.campussync_backend.service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${campussync.password-reset-url}")
    private String passwordResetUrl;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendPasswordResetEmail(
            String recipientEmail,
            String token) {

        // Encode the token so it is safe to include in a URL.
        String encodedToken = URLEncoder.encode(
                token,
                StandardCharsets.UTF_8
        );

        // Append the token to the configured reset URL.
        String separator = passwordResetUrl.contains("?")
                ? "&"
                : "?";

        String resetLink = passwordResetUrl
                + separator
                + "token="
                + encodedToken;

        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(fromEmail);
        message.setTo(recipientEmail);
        message.setSubject("CampusSync - Password Reset");

        message.setText(
                "Hello,\n\n"
                + "We received a request to reset your CampusSync password.\n\n"
                + "Use the link below to reset your password:\n"
                + resetLink + "\n\n"
                + "This link expires in 30 minutes and can only be used once.\n\n"
                + "If you did not request this reset, you can ignore this email.\n\n"
                + "CampusSync Support"
        );

        mailSender.send(message);
    }
}
