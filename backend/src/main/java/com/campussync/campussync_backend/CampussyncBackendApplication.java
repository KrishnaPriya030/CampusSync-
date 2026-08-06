package com.campussync.campussync_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

@SpringBootApplication
public class CampussyncBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(
            CampussyncBackendApplication.class,
            args
        );
    }

}
