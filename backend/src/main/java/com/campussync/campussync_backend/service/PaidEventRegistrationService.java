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
import com.campussync.campussync_backend.enums.CapacityType;
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

        // ========================================================
        // FIND STUDENT
        // ========================================================

        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Student profile not found"));

        // ========================================================
        // LOCK EVENT ROW
        // ========================================================

        Event event = eventRepository.findByIdForUpdate(eventId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Event not found"));

        // ========================================================
        // EVENT MUST EXIST AND NOT BE DELETED
        // ========================================================

        if (event.isDeleted()) {
            throw new RuntimeException(
                    "Event not found");
        }

        // ========================================================
        // EVENT MUST BE PUBLISHED
        // ========================================================

        if (event.getStatus() != EventStatus.PUBLISHED) {
            throw new RuntimeException(
                    "Registration is available only for published events");
        }

        // ========================================================
        // MUST BE A PAID EVENT
        // ========================================================

        if (event.getPaymentType() != PaymentType.PAID) {
            throw new RuntimeException(
                    "This is not a paid event");
        }

        // ========================================================
        // CHECK REGISTRATION DEADLINE
        // ========================================================

        if (event.getRegistrationDeadline() != null
                && LocalDateTime.now()
                        .isAfter(event.getRegistrationDeadline())) {

            throw new RuntimeException(
                    "Registration deadline has passed");
        }

        // ========================================================
        // PREVENT DUPLICATE REGISTRATION
        // ========================================================

        if (registrationRepository.existsByEventIdAndStudentId(
                eventId,
                student.getId())) {

            throw new RuntimeException(
                    "Student is already registered for this event");
        }

        // ========================================================
        // CAPACITY CHECK
        //
        // PAYMENT_PENDING registrations also reserve seats.
        // ========================================================

        if (event.getCapacityType() == CapacityType.LIMITED) {

            if (event.getCapacity() == null
                    || event.getCapacity() <= 0) {

                throw new RuntimeException(
                        "Event capacity is invalid");
            }

            long registeredCount =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.REGISTERED);

            long pendingCount =
                    registrationRepository.countByEventIdAndStatus(
                            eventId,
                            EventRegistrationStatus.PAYMENT_PENDING);

            long reservedSeats =
                    registeredCount + pendingCount;

            if (reservedSeats >= event.getCapacity()) {

                throw new RuntimeException(
                        "Event registration capacity is full");
            }
        }

        // ========================================================
        // GET EVENT FEE
        // ========================================================

        BigDecimal amount = event.getRegistrationFee();

        if (amount == null
                || amount.compareTo(BigDecimal.ZERO) <= 0) {

            throw new RuntimeException(
                    "Paid event must have a valid registration fee");
        }

        // ========================================================
        // CREATE RAZORPAY ORDER
        // ========================================================

        try {

            long amountInPaise = amount
                    .multiply(BigDecimal.valueOf(100))
                    .longValueExact();

            JSONObject orderRequest = new JSONObject();

            orderRequest.put(
                    "amount",
                    amountInPaise);

            orderRequest.put(
                    "currency",
                    "INR");

            String receipt =
                    "CAMPUS_"
                    + eventId
                    + "_"
                    + student.getId()
                    + "_"
                    + System.currentTimeMillis();

            orderRequest.put(
                    "receipt",
                    receipt);

            Order order =
                    razorpayClient.orders.create(orderRequest);

            // ====================================================
            // CREATE PAYMENT-PENDING REGISTRATION
            // ====================================================

            EventRegistration registration =
                    new EventRegistration();

            registration.setEvent(event);
            registration.setStudent(student);

            registration.setStatus(
                    EventRegistrationStatus.PAYMENT_PENDING);

            LocalDateTime now =
                    LocalDateTime.now();

            registration.setRegisteredAt(now);

            registration.setPaymentExpiresAt(
                    now.plusMinutes(15));

            EventRegistration savedRegistration =
                    registrationRepository.save(registration);

            // ====================================================
            // CREATE PENDING PAYMENT
            // ====================================================

            Payment payment =
                    new Payment();

            payment.setRegistration(
                    savedRegistration);

            payment.setAmount(amount);

            payment.setStatus(
                    PaymentStatus.PENDING);

            payment.setRazorpayOrderId(
                    order.get("id"));

            payment.setCreatedAt(now);

            paymentRepository.save(payment);

            // ====================================================
            // RETURN RAZORPAY ORDER DETAILS
            // ====================================================

            return new RazorpayOrderResponse(
                    savedRegistration.getId(),
                    event.getId(),
                    amount,
                    "INR",
                    order.get("id"),
                    razorpayKeyId);

        } catch (RazorpayException e) {

            throw new RuntimeException(
                    "Unable to create Razorpay order",
                    e);
        }
    }
}