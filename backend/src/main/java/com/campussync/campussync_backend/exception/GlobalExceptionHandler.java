package com.campussync.campussync_backend.exception;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(InvalidCredentialsException.class)
    public ResponseEntity<Map<String, String>> handleInvalidCredentials(
            InvalidCredentialsException exception) {

        return ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(Map.of(
                        "message",
                        exception.getMessage()
                ));
                
    }
    @ExceptionHandler(AccountNotActiveException.class)
public ResponseEntity<Map<String, String>> handleAccountNotActive(
        AccountNotActiveException exception) {

    return ResponseEntity
            .status(HttpStatus.FORBIDDEN)
            .body(Map.of(
                    "message",
                    exception.getMessage()
            ));
}
@ExceptionHandler(PasswordMismatchException.class)
public ResponseEntity<Map<String, String>> handlePasswordMismatch(
        PasswordMismatchException exception) {

    return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(Map.of(
                    "message",
                    exception.getMessage()
            ));
}
}