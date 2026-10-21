package com.campussync.campussync_backend.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.campussync.campussync_backend.entity.CertificateTemplate;
import com.campussync.campussync_backend.service.CertificateTemplateService;

@RestController
@RequestMapping("/api/organizer/certificate-templates")
public class CertificateTemplateController {

    private final CertificateTemplateService service;

    public CertificateTemplateController(CertificateTemplateService service) {
        this.service = service;
    }

    @GetMapping
    public List<CertificateTemplate> getAllTemplates() {
        return service.getAll();
    }

    @GetMapping("/{id}")
    public CertificateTemplate getTemplate(@PathVariable Long id) {
        return service.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CertificateTemplate createTemplate(@RequestBody CertificateTemplate request) {
        return service.create(request);
    }

    @PutMapping("/{id}")
    public CertificateTemplate updateTemplate(
            @PathVariable Long id,
            @RequestBody CertificateTemplate request) {
        return service.update(id, request);
    }
}