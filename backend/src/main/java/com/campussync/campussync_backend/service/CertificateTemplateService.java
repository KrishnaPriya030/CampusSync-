package com.campussync.campussync_backend.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campussync.campussync_backend.entity.CertificateTemplate;
import com.campussync.campussync_backend.repository.CertificateTemplateRepository;

@Service
public class CertificateTemplateService {

    private final CertificateTemplateRepository repository;

    public CertificateTemplateService(CertificateTemplateRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<CertificateTemplate> getAll() {
        return repository.findAll();
    }

    @Transactional(readOnly = true)
    public CertificateTemplate getById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Certificate template not found: " + id));
    }

    @Transactional
    public CertificateTemplate create(CertificateTemplate input) {
        validate(input);
        String name = input.getName().trim();
        if (repository.existsByName(name)) {
            throw new IllegalArgumentException("A certificate template with this name already exists");
        }
        input.setId(null);
        input.setName(name);
        return repository.save(input);
    }

    @Transactional
    public CertificateTemplate update(Long id, CertificateTemplate input) {
        validate(input);
        CertificateTemplate existing = getById(id);
        String name = input.getName().trim();
        repository.findByName(name).ifPresent(found -> {
            if (!found.getId().equals(id)) {
                throw new IllegalArgumentException("A certificate template with this name already exists");
            }
        });

        existing.setName(name);
        existing.setTemplateType(input.getTemplateType().trim());
        existing.setBackgroundUrl(input.getBackgroundUrl());
        existing.setOrganizationName(input.getOrganizationName());
        existing.setCertificateTitle(input.getCertificateTitle());
        existing.setDescription(input.getDescription());
        existing.setSignature1Name(input.getSignature1Name());
        existing.setSignature1Designation(input.getSignature1Designation());
        existing.setSignature1ImageUrl(input.getSignature1ImageUrl());
        existing.setSignature2Name(input.getSignature2Name());
        existing.setSignature2Designation(input.getSignature2Designation());
        existing.setSignature2ImageUrl(input.getSignature2ImageUrl());
        existing.setFont(input.getFont());
        existing.setPrimaryColor(input.getPrimaryColor());
        existing.setSecondaryColor(input.getSecondaryColor());
        return repository.save(existing);
    }

    private void validate(CertificateTemplate template) {
        if (template == null) {
            throw new IllegalArgumentException("Template body is required");
        }
        if (template.getName() == null || template.getName().isBlank()) {
            throw new IllegalArgumentException("Template name is required");
        }
        if (template.getTemplateType() == null || template.getTemplateType().isBlank()) {
            throw new IllegalArgumentException("Template type is required");
        }
    }
}
