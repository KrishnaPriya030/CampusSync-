package com.campussync.campussync_backend.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(
    name = "device_tokens",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_device_token",
            columnNames = "token"
        )
    }
)
@Getter
@Setter
public class DeviceToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, unique = true, length = 500)
    private String token;

    @Column(length = 30)
    private String platform;

    @Column(nullable = false)
    private boolean active = true;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime lastUsedAt;
}