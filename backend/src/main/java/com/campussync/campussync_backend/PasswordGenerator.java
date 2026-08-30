package com.campussync.campussync_backend;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class PasswordGenerator {

    public static void main(String[] args) {

        BCryptPasswordEncoder encoder =
                new BCryptPasswordEncoder();

        String password = "Temp@123";

        String hashedPassword =
                encoder.encode(password);

        System.out.println(hashedPassword);
    }
}