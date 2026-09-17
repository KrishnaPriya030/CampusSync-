package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.razorpay.Utils;

@Service
public class RazorpayPaymentVerificationService {

    private final PaymentRepository paymentRepository;
    private final EventRegistrationRepository registrationRepository;

    public RazorpayPaymentVerificationService(
            PaymentRepository paymentRepository,
            EventRegistrationRepository registrationRepository) {

        this.paymentRepository = paymentRepository;
        this.registrationRepository = registrationRepository;
    }

    @Transactional
    public void verifyPayment(
            Long userId,
            String razorpayOrderId,
            String razorpayPaymentId,
            String razorpaySignature) {

        // Find the payment using the Razorpay order ID
        Payment payment = paymentRepository
                .findByRazorpayOrderId(razorpayOrderId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Payment record not found"));

        EventRegistration registration =
                payment.getRegistration();

        // Make sure this payment belongs to the logged-in student
        if (!registration.getStudent()
                .getUser()
                .getId()
                .equals(userId)) {

            throw new RuntimeException(
                    "You can verify only your own payment");
        }

        // Payment must still be pending
        if (payment.getStatus() != PaymentStatus.PENDING) {

            throw new RuntimeException(
                    "Payment is not in a pending state");
        }

        // Registration must still be waiting for payment
        if (registration.getStatus()
                != EventRegistrationStatus.PAYMENT_PENDING) {

            throw new RuntimeException(
                    "Registration is not awaiting payment");
        }

        // Verify Razorpay signature
        try {

            String secret =
                    System.getenv("RAZORPAY_KEY_SECRET");

            if (secret == null || secret.isBlank()) {

                throw new RuntimeException(
                        "Razorpay secret is not configured");
            }

            String payload =
                    razorpayOrderId
                    + "|"
                    + razorpayPaymentId;

            boolean valid =
                    Utils.verifySignature(
                            payload,
                            razorpaySignature,
                            secret);

            if (!valid) {

                throw new RuntimeException(
                        "Invalid Razorpay payment signature");
            }

        } catch (Exception e) {

            throw new RuntimeException(
                    "Payment verification failed",
                    e);
        }

        // Signature is valid
        payment.setRazorpayPaymentId(
                razorpayPaymentId);

        payment.setRazorpaySignature(
                razorpaySignature);

        payment.setStatus(
                PaymentStatus.PAID);

        payment.setPaidAt(
                LocalDateTime.now());

        payment.setUpdatedAt(
                LocalDateTime.now());

        paymentRepository.save(payment);

        // Confirm the event registration
        registration.setStatus(
                EventRegistrationStatus.REGISTERED);

        registration.setConfirmedAt(
                LocalDateTime.now());

        registrationRepository.save(registration);
    }
}