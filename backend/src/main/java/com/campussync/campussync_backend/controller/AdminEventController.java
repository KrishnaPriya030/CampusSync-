package com.campussync.campussync_backend.controller;

import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.campussync.campussync_backend.dto.EventResponse;
import com.campussync.campussync_backend.service.AdminEventService;

@RestController
@RequestMapping("/api/admin/events")
public class AdminEventController {
    private final AdminEventService adminEventService;

    public AdminEventController(AdminEventService adminEventService) {
        this.adminEventService = adminEventService;
    }

    @GetMapping
    public List<EventResponse> getAllEvents() {
        return adminEventService.getAllEvents();
    }
}

