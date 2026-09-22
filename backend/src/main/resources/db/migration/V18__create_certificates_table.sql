CREATE TABLE certificates (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    certificate_number VARCHAR(255) NOT NULL,
    issued_at DATETIME NOT NULL,
    issued_by_user_id BIGINT NOT NULL,
    certificate_url VARCHAR(255) NULL,

    PRIMARY KEY (id),

    CONSTRAINT uk_certificate_event_student
        UNIQUE (event_id, student_id),

    CONSTRAINT uk_certificate_number
        UNIQUE (certificate_number),

    CONSTRAINT fk_certificate_event
        FOREIGN KEY (event_id)
        REFERENCES events(id),

    CONSTRAINT fk_certificate_student
        FOREIGN KEY (student_id)
        REFERENCES students(id),

    CONSTRAINT fk_certificate_issued_by
        FOREIGN KEY (issued_by_user_id)
        REFERENCES users(id)
);