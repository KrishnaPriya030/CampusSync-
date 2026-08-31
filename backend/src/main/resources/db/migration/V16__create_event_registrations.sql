CREATE TABLE event_registrations (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    event_id BIGINT NOT NULL,

    student_id BIGINT NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'REGISTERED',

    registered_at DATETIME NOT NULL,

    payment_expires_at DATETIME NULL,

    confirmed_at DATETIME NULL,

    CONSTRAINT uk_event_student
        UNIQUE (event_id, student_id),

    CONSTRAINT fk_registration_event
        FOREIGN KEY (event_id)
        REFERENCES events(id),

    CONSTRAINT fk_registration_student
        FOREIGN KEY (student_id)
        REFERENCES students(id)

);