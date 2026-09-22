package com.campussync.campussync_backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.NotificationType;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;

@Service
public class PaymentReservationExpiryService {

    private final EventRegistrationRepository registrationRepository;
    private final PaymentRepository paymentRepository;
    private final NotificationService notificationService;

    public PaymentReservationExpiryService(
            EventRegistrationRepository registrationRepository,
            PaymentRepository paymentRepository,
            NotificationService notificationService) {

        this.registrationRepository = registrationRepository;
        this.paymentRepository = paymentRepository;
        this.notificationService = notificationService;
    }

    // ============================================================
    // AUTOMATIC PAYMENT RESERVATION EXPIRY
    // Runs every minute
    // ============================================================

    @Scheduled(fixedRate = 60000)
    @Transactional
    public void expirePaymentReservations() {

        LocalDateTime now = LocalDateTime.now();

        List<EventRegistration> expiredRegistrations =
                registrationRepository
                        .findByStatusAndPaymentExpiresAtLessThanEqual(
                                EventRegistrationStatus.PAYMENT_PENDING,
                                now);

        for (EventRegistration registration :
                expiredRegistrations) {

            // Re-check status because another request may have
            // completed/cancelled the registration meanwhile.
            if (registration.getStatus()
                    != EventRegistrationStatus.PAYMENT_PENDING) {
                continue;
            }

            Payment payment =
                    paymentRepository
                            .findByRegistrationId(
                                    registration.getId())
                            .orElse(null);

            // Mark payment as failed if a payment record exists.
            if (payment != null
                    && payment.getStatus()
                    == PaymentStatus.PENDING) {

                payment.setStatus(
                        PaymentStatus.FAILED);

                payment.setUpdatedAt(now);

                paymentRepository.save(payment);
            }

            // Release the registration/seat.
            registration.setStatus(
                    EventRegistrationStatus.CANCELLED);

            registration.setPaymentExpiresAt(null);

            registrationRepository.save(registration);

            // Notify the student.
            notificationService.createNotification(
                    registration.getStudent()
                            .getUser()
                            .getId(),

                    "Payment Failed",

                    "Your payment reservation for the event \""
                            + registration.getEvent().getTitle()
                            + "\" has expired. "
                            + "Your registration was cancelled.",

                    NotificationType.PAYMENT_FAILED,

                    registration.getEvent()
            );
        }
    }
}