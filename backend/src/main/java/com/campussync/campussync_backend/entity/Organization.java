
package com.campussync.campussync_backend.entity;

import java.util.List;

import com.campussync.campussync_backend.enums.OrganizationType;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;

@Entity
@Table(name = "organizations")
public class Organization {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    private String name;

    @NotBlank
    private String code;

    @Enumerated(EnumType.STRING)
    private OrganizationType organizationType;

  @OneToMany(mappedBy = "organization")
  private List<Organizer> organizers;

    @NotBlank
    private String description;

    private boolean active;

}

