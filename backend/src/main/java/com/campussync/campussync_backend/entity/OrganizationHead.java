        package com.campussync.campussync_backend.entity;

        import jakarta.persistence.Entity;
        import jakarta.persistence.GeneratedValue;
        import jakarta.persistence.GenerationType;
        import jakarta.persistence.Id;
        import jakarta.persistence.JoinColumn;
        import jakarta.persistence.OneToOne;
        import jakarta.persistence.Table;
        import jakarta.validation.constraints.NotBlank;

        import lombok.Getter;
        import lombok.Setter;

        @Entity
        @Table(name = "organization_heads")
        @Getter
        @Setter
        public class OrganizationHead {

            @Id
            @GeneratedValue(strategy = GenerationType.IDENTITY)
            private Long id;

            @OneToOne
            @JoinColumn(
                name = "user_id",
                nullable = false,
                unique = true
            )
            private User user;

            @OneToOne
            @JoinColumn(
                name = "organization_id",
                nullable = false,
                unique = true
            )
            private Organization organization;

            @NotBlank
            private String designation;
        }