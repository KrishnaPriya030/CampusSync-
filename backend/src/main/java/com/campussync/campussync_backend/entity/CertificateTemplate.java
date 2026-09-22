
package com.campussync.campussync_backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "certificate_templates")
@Getter
@Setter
public class CertificateTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(nullable = false)
    private String templateType;

    @Column(name = "background_url")
    private String backgroundUrl;

    @Column(name = "organization_name")
    private String organizationName;

    @Column(name = "certificate_title")
    private String certificateTitle;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "signature1_name")
    private String signature1Name;

    @Column(name = "signature1_designation")
    private String signature1Designation;

    @Column(name = "signature1_image_url")
    private String signature1ImageUrl;

    @Column(name = "signature2_name")
    private String signature2Name;

    @Column(name = "signature2_designation")
    private String signature2Designation;

    @Column(name = "signature2_image_url")
    private String signature2ImageUrl;

    private String font;

    @Column(name = "primary_color")
    private String primaryColor;

    @Column(name = "secondary_color")
    private String secondaryColor;
}

