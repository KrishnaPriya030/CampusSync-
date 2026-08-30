package com.campussync.campussync_backend.service;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class StudentAccountExpiryScheduler {

    private final StudentAccountExpiryService expiryService;

    public StudentAccountExpiryScheduler(
            StudentAccountExpiryService expiryService) {

        this.expiryService = expiryService;
    }

    @Scheduled(cron = "0 0 0 * * *")
    public void checkStudentAccounts() {

        expiryService.deactivateCompletedStudents();
    }
}
