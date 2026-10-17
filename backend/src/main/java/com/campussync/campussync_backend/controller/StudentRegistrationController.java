
        package com.campussync.campussync_backend.controller;

        import java.util.List;

        import jakarta.validation.Valid;

        import org.springframework.http.HttpStatus;
        import org.springframework.http.ResponseEntity;
        import org.springframework.security.core.Authentication;
        import org.springframework.web.bind.annotation.*;
        import org.springframework.web.server.ResponseStatusException;

        import com.campussync.campussync_backend.dto.EventRegistrationResponse;
        import com.campussync.campussync_backend.dto.RazorpayOrderResponse;
        import com.campussync.campussync_backend.dto.RazorpayPaymentVerificationRequest;
        import com.campussync.campussync_backend.entity.User;
        import com.campussync.campussync_backend.enums.Role;
        import com.campussync.campussync_backend.service.PaidEventRegistrationService;
        import com.campussync.campussync_backend.service.RazorpayPaymentVerificationService;
        import com.campussync.campussync_backend.service.StudentCancellationService;
        import com.campussync.campussync_backend.service.StudentRegistrationService;

        @RestController
        @RequestMapping("/api/student/registrations")
        public class StudentRegistrationController {

        private final StudentRegistrationService registrationService;
        private final StudentCancellationService cancellationService;
        private final PaidEventRegistrationService paidEventRegistrationService;
        private final RazorpayPaymentVerificationService razorpayPaymentVerificationService;

        public StudentRegistrationController(
                StudentRegistrationService registrationService,
                StudentCancellationService cancellationService,
                PaidEventRegistrationService paidEventRegistrationService,
                RazorpayPaymentVerificationService razorpayPaymentVerificationService) {

                this.registrationService = registrationService;
                this.cancellationService = cancellationService;
                this.paidEventRegistrationService = paidEventRegistrationService;
                this.razorpayPaymentVerificationService =
                        razorpayPaymentVerificationService;
        }

        // FREE EVENT REGISTRATION
        @PostMapping("/event/{eventId}")
        public ResponseEntity<EventRegistrationResponse> registerForEvent(
                @PathVariable Long eventId,
                Authentication authentication) {

                User user = getAuthenticatedStudent(authentication);

                return ResponseEntity.ok(
                        registrationService.registerStudent(
                                user.getId(),
                                eventId
                        )
                );
        }

        // PAID EVENT: CREATE RAZORPAY ORDER
        @PostMapping("/event/{eventId}/payment")
        public ResponseEntity<RazorpayOrderResponse> createPaymentOrder(
                @PathVariable Long eventId,
                Authentication authentication) {

                User user = getAuthenticatedStudent(authentication);

                return ResponseEntity.ok(
                        paidEventRegistrationService.createOrder(
                                user.getId(),
                                eventId
                        )
                );
        }

        // VERIFY RAZORPAY PAYMENT
        @PostMapping("/payment/verify")
        public ResponseEntity<String> verifyPayment(
                @Valid @RequestBody RazorpayPaymentVerificationRequest request,
                Authentication authentication) {

                User user = getAuthenticatedStudent(authentication);

                razorpayPaymentVerificationService.verifyPayment(
                        user.getId(),
                        request.razorpayOrderId(),
                        request.razorpayPaymentId(),
                        request.razorpaySignature()
                );

                return ResponseEntity.ok(
                        "Payment verified successfully and registration confirmed"
                );
        }

        // GET THE CURRENT STUDENT'S REGISTRATIONS
        @GetMapping
        public ResponseEntity<List<EventRegistrationResponse>> getMyRegistrations(
                Authentication authentication) {

                User user = getAuthenticatedStudent(authentication);

                return ResponseEntity.ok(
                        registrationService.getMyRegistrations(
                                user.getId()
                        )
                );
        }

        // CANCEL A REGISTRATION
        @PutMapping("/{registrationId}/cancel")
        public ResponseEntity<EventRegistrationResponse> cancelRegistration(
                @PathVariable Long registrationId,
                Authentication authentication) {

                User user = getAuthenticatedStudent(authentication);

                return ResponseEntity.ok(
                        cancellationService.cancelRegistration(
                                user.getId(),
                                registrationId
                        )
                );
        }

        // VERIFY AUTHENTICATION AND STUDENT ROLE
        private User getAuthenticatedStudent(
                Authentication authentication) {

                if (authentication == null
                        || !authentication.isAuthenticated()) {

                throw new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Student authentication required"
                );
                }

                Object principal = authentication.getPrincipal();

                if (!(principal instanceof User)) {

                throw new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Invalid authenticated user"
                );
                }

                User user = (User) principal;

                if (user.getRole() != Role.STUDENT) {

                throw new ResponseStatusException(
                        HttpStatus.FORBIDDEN,
                        "Student access required"
                );
                }

                return user;
        }
        }
