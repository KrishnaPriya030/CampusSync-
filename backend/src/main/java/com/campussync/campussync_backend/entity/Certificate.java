
package com.campussync.campussync_backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "certificates",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_certificate_event_student",
                        columnNames = {"event_id", "student_id"}
                ),
                @UniqueConstraint(
                        name = "uk_certificate_number",
                        columnNames = {"certificate_number"}
                )
        }
)
@Getter
@Setter
public class Certificate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @ManyToOne(optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @Column(name = "certificate_number", nullable = false, unique = true)
    private String certificateNumber;

    @Column(nullable = false)
    private LocalDateTime issuedAt;

    @ManyToOne(optional = false)
    @JoinColumn(name = "issued_by_user_id", nullable = false)
    private User issuedBy;

    @Column(name = "certificate_url")
    private String certificateUrl;
    @ManyToOne(optional = false)
@JoinColumn(name = "certificate_template_id", nullable = false)
private CertificateTemplate certificateTemplate;
}
