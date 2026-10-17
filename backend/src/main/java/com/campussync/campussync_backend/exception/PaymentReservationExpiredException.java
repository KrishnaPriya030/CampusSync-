
package com.campussync.campussync_backend.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.CONFLICT)
public class PaymentReservationExpiredException extends RuntimeException {

    public PaymentReservationExpiredException() {
        super("Payment reservation has expired");
    }
}
