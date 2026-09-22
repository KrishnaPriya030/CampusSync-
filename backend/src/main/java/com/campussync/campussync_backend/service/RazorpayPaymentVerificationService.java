package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.json.JSONObject;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.razorpay.RazorpayClient;
import com.razorpay.Utils;

@Service
public class RazorpayPaymentVerificationService {

    private final PaymentRepository paymentRepository;
    private final EventRegistrationRepository registrationRepository;
    private final NotificationService notificationService;
    private final RazorpayClient razorpayClient;

    public RazorpayPaymentVerificationService(
            PaymentRepository paymentRepository,
            EventRegistrationRepository registrationRepository,
            NotificationService notificationService,
            RazorpayClient razorpayClient) {

        this.paymentRepository = paymentRepository;
        this.registrationRepository = registrationRepository;
        this.notificationService = notificationService;
        this.razorpayClient = razorpayClient;
    }

    @Transactional
    public void verifyPayment(
            Long userId,
            String razorpayOrderId,
            String razorpayPaymentId,
            String razorpaySignature) {

        // ========================================================
        // BASIC INPUT VALIDATION
        // ========================================================

        if (razorpayOrderId == null || razorpayOrderId.isBlank()) {
            throw new RuntimeException(
                    "Razorpay order ID is required");
        }

        if (razorpayPaymentId == null || razorpayPaymentId.isBlank()) {
            throw new RuntimeException(
                    "Razorpay payment ID is required");
        }

        if (razorpaySignature == null || razorpaySignature.isBlank()) {
            throw new RuntimeException(
                    "Razorpay payment signature is required");
        }

        // ========================================================
        // FIND PAYMENT WITH DATABASE LOCK
        // ========================================================

        Payment payment = paymentRepository
                .findByRazorpayOrderIdForUpdate(razorpayOrderId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Payment record not found"));

        EventRegistration registration =
                payment.getRegistration();

        // ========================================================
        // VERIFY PAYMENT OWNERSHIP
        // ========================================================

        if (!registration.getStudent()
                .getUser()
                .getId()
                .equals(userId)) {

            throw new RuntimeException(
                    "You can verify only your own payment");
        }

        // ========================================================
        // PAYMENT MUST BE PENDING
        // ========================================================

        if (payment.getStatus() != PaymentStatus.PENDING) {

            throw new RuntimeException(
                    "Payment is not in a pending state");
        }

        // ========================================================
        // REGISTRATION MUST BE PAYMENT_PENDING
        // ========================================================

        if (registration.getStatus()
                != EventRegistrationStatus.PAYMENT_PENDING) {

            throw new RuntimeException(
                    "Registration is not awaiting payment");
        }

        // ========================================================
        // CHECK PAYMENT EXPIRY
        // ========================================================

        LocalDateTime now = LocalDateTime.now();

        LocalDateTime paymentExpiry =
                registration.getPaymentExpiresAt();

        if (paymentExpiry == null
                || !now.isBefore(paymentExpiry)) {

            payment.setStatus(
                    PaymentStatus.FAILED);

            payment.setUpdatedAt(now);

            paymentRepository.save(payment);

            registration.setStatus(
                    EventRegistrationStatus.CANCELLED);

            registration.setPaymentExpiresAt(null);

            registrationRepository.save(registration);

            notificationService.createNotification(
                    userId,
                    "Payment Failed",
                    "Your payment reservation for the event \""
                            + registration.getEvent().getTitle()
                            + "\" has expired. Your registration was cancelled.",
                    NotificationType.PAYMENT_FAILED,
                    registration.getEvent()
            );

            throw new RuntimeException(
                    "Payment reservation has expired");
        }

        // ========================================================
        // VERIFY RAZORPAY SIGNATURE
        // ========================================================

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

        // ========================================================
        // FETCH ACTUAL PAYMENT FROM RAZORPAY
        // ========================================================

        try {

            com.razorpay.Payment razorpayPayment =
                    razorpayClient.payments.fetch(
                            razorpayPaymentId);

            JSONObject paymentJson =
                    razorpayPayment.toJson();

            // ====================================================
            // VERIFY PAYMENT BELONGS TO OUR ORDER
            // ====================================================

            String actualOrderId =
                    paymentJson.optString(
                            "order_id",
                            "");

            if (!razorpayOrderId.equals(actualOrderId)) {

                throw new RuntimeException(
                        "Razorpay payment does not belong to this order");
            }

            // ====================================================
            // VERIFY PAYMENT STATUS
            // ====================================================

            String razorpayStatus =
                    paymentJson.optString(
                            "status",
                            "");

            if (!"captured".equalsIgnoreCase(razorpayStatus)) {

                throw new RuntimeException(
                        "Razorpay payment is not captured");
            }

            // ====================================================
            // VERIFY AMOUNT
            // ====================================================

            long razorpayAmountPaise =
                    paymentJson.optLong(
                            "amount",
                            -1);

            if (razorpayAmountPaise < 0) {

                throw new RuntimeException(
                        "Razorpay payment amount is missing");
            }

            BigDecimal expectedAmount =
                    payment.getAmount();

            long expectedAmountPaise =
                    expectedAmount
                            .multiply(BigDecimal.valueOf(100))
                            .longValueExact();

            if (razorpayAmountPaise
                    != expectedAmountPaise) {

                throw new RuntimeException(
                        "Razorpay payment amount does not match the registration amount");
            }

            // ====================================================
            // VERIFY CURRENCY
            // ====================================================

            String currency =
                    paymentJson.optString(
                            "currency",
                            "");

            if (!"INR".equalsIgnoreCase(currency)) {

                throw new RuntimeException(
                        "Invalid payment currency");
            }

        } catch (Exception e) {

            throw new RuntimeException(
                    "Razorpay payment details verification failed",
                    e);
        }

        // ========================================================
        // PAYMENT SUCCESS
        // ========================================================

        payment.setRazorpayPaymentId(
                razorpayPaymentId);

        payment.setRazorpaySignature(
                razorpaySignature);

        payment.setStatus(
                PaymentStatus.PAID);

        payment.setPaidAt(now);

        payment.setUpdatedAt(now);

        paymentRepository.save(payment);

        // ========================================================
        // CONFIRM REGISTRATION
        // ========================================================

        registration.setStatus(
                EventRegistrationStatus.REGISTERED);

        registration.setConfirmedAt(now);

        registration.setPaymentExpiresAt(null);

        registrationRepository.save(registration);

        // ========================================================
        // PAYMENT SUCCESS NOTIFICATION
        // ========================================================

        notificationService.createNotification(
                userId,
                "Payment Successful",
                "Your payment for the event \""
                        + registration.getEvent().getTitle()
                        + "\" was successful.",
                NotificationType.PAYMENT_SUCCESS,
                registration.getEvent()
        );

        // ========================================================
        // REGISTRATION CONFIRMED NOTIFICATION
        // ========================================================

        notificationService.createNotification(
                userId,
                "Registration Confirmed",
                "You are successfully registered for the event \""
                        + registration.getEvent().getTitle()
                        + "\".",
                NotificationType.REGISTRATION_CONFIRMED,
                registration.getEvent()
        );
    }
}