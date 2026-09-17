package com.campussync.campussync_backend.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.dto.RazorpayOrderResponse;
import com.campussync.campussync_backend.entity.Event;
import com.campussync.campussync_backend.entity.EventRegistration;
import com.campussync.campussync_backend.entity.Payment;
import com.campussync.campussync_backend.entity.Student;
import com.campussync.campussync_backend.enums.EventRegistrationStatus;
import com.campussync.campussync_backend.enums.EventStatus;
import com.campussync.campussync_backend.enums.PaymentStatus;
import com.campussync.campussync_backend.enums.PaymentType;
import com.campussync.campussync_backend.repository.EventRegistrationRepository;
import com.campussync.campussync_backend.repository.EventRepository;
import com.campussync.campussync_backend.repository.PaymentRepository;
import com.campussync.campussync_backend.repository.StudentRepository;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;

@Service
public class PaidEventRegistrationService {

    private final EventRepository eventRepository;
    private final StudentRepository studentRepository;
    private final EventRegistrationRepository registrationRepository;
    private final PaymentRepository paymentRepository;
    private final RazorpayClient razorpayClient;

    @Value("${razorpay.key.id}")
    private String razorpayKeyId;

    public PaidEventRegistrationService(
            EventRepository eventRepository,
            StudentRepository studentRepository,
            EventRegistrationRepository registrationRepository,
            PaymentRepository paymentRepository,
            RazorpayClient razorpayClient) {

        this.eventRepository = eventRepository;
        this.studentRepository = studentRepository;
        this.registrationRepository = registrationRepository;
        this.paymentRepository = paymentRepository;
        this.razorpayClient = razorpayClient;
    }

    @Transactional
    public RazorpayOrderResponse createOrder(
            Long userId,
            Long eventId) {

        // Find the logged-in student's profile
        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException("Student profile not found"));

        // Find the event
        Event event = eventRepository.findByIdAndDeletedFalse(eventId)
                .orElseThrow(() ->
                        new RuntimeException("Event not found"));

        // Only published events can accept registrations
        if (event.getStatus() != EventStatus.PUBLISHED) {
            throw new RuntimeException(
                    "Registration is available only for published events");
        }

        // Make sure this is a paid event
        if (event.getPaymentType() != PaymentType.PAID) {
            throw new RuntimeException(
                    "This is not a paid event");
        }

        // Check registration deadline
        if (event.getRegistrationDeadline() != null
                && LocalDateTime.now()
                        .isAfter(event.getRegistrationDeadline())) {

            throw new RuntimeException(
                    "Registration deadline has passed");
        }

        // Prevent duplicate registration
        if (registrationRepository.existsByEventIdAndStudentId(
                eventId,
                student.getId())) {

            throw new RuntimeException(
                    "Student is already registered for this event");
        }

        // Check event capacity
        if (event.getCapacityType() != null
                && event.getCapacityType().name().equals("LIMITED")) {

            long registeredCount =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.REGISTERED);

            long pendingCount =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.PAYMENT_PENDING);

            if (event.getCapacity() != null
                    && registeredCount + pendingCount
                            >= event.getCapacity()) {

                throw new RuntimeException(
                        "Event registration capacity is full");
            }
        }

        // Get the event fee
        BigDecimal amount = event.getRegistrationFee();

        if (amount == null
                || amount.compareTo(BigDecimal.ZERO) <= 0) {

            throw new RuntimeException(
                    "Paid event must have a valid registration fee");
        }

        try {

            /*
             * Razorpay expects the amount in paise.
             *
             * Example:
             * ₹500 = 50000 paise
             */
            long amountInPaise = amount
                    .multiply(BigDecimal.valueOf(100))
                    .longValueExact();

            JSONObject orderRequest = new JSONObject();

            orderRequest.put(
                    "amount",
                    amountInPaise
            );

            orderRequest.put(
                    "currency",
                    "INR"
            );

            String receipt =
                    "CAMPUS_"
                    + eventId
                    + "_"
                    + student.getId()
                    + "_"
                    + System.currentTimeMillis();

            orderRequest.put(
                    "receipt",
                    receipt
            );

            // Create Razorpay order
            Order order =
                    razorpayClient.orders.create(orderRequest);

            // Create pending event registration
            EventRegistration registration =
                    new EventRegistration();

            registration.setEvent(event);

            registration.setStudent(student);

            registration.setStatus(
                    EventRegistrationStatus.PAYMENT_PENDING);

            registration.setRegisteredAt(
                    LocalDateTime.now());

            EventRegistration savedRegistration =
                    registrationRepository.save(registration);

            // Create pending payment
            Payment payment =
                    new Payment();

            payment.setRegistration(
                    savedRegistration);

            payment.setAmount(
                    amount);

            payment.setStatus(
                    PaymentStatus.PENDING);

            payment.setRazorpayOrderId(
                    order.get("id"));

            payment.setCreatedAt(
                    LocalDateTime.now());

            paymentRepository.save(payment);

            // Send Razorpay order information to frontend
            return new RazorpayOrderResponse(
                    savedRegistration.getId(),
                    event.getId(),
                    amount,
                    "INR",
                    order.get("id"),
                    razorpayKeyId
            );

        } catch (RazorpayException e) {

            throw new RuntimeException(
                    "Unable to create Razorpay order",
                    e);
        }
    }
}