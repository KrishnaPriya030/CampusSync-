package com.campussync.campussync_backend.entity;

import java.util.List;

import com.campussync.campussync_backend.enums.OrganizationType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;

import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "organizations")
@Getter
@Setter
public class Organization {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Column(nullable = false)
    private String name;

    @NotBlank
    @Column(nullable = false)
    private String code;

    @Enumerated(EnumType.STRING)
    private OrganizationType organizationType;

    /*
     * Nullable because college-wide organizations
     * don't belong to a particular department.
     *
     * Explicitly mapped to the existing database
     * column department_id.
     */
    @ManyToOne
    @JoinColumn(name = "department_id")
    private Department department;

    @OneToMany(mappedBy = "organization")
    private List<Organizer> organizers;

    @NotBlank
    @Column(nullable = false)
    private String description;

    private boolean active;
}