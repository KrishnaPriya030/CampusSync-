CREATE TABLE events (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    organizer_id BIGINT NOT NULL,

    title VARCHAR(255) NOT NULL,

    description TEXT NOT NULL,

    venue VARCHAR(255) NOT NULL,

    start_date_time DATETIME NOT NULL,

    end_date_time DATETIME NOT NULL,

    registration_deadline DATETIME NOT NULL,

    capacity_type VARCHAR(20) NOT NULL,

    capacity INT NULL,

    payment_type VARCHAR(20) NOT NULL,

    registration_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    refund_policy TEXT NULL,

    attendance_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    certificate_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',

    deleted BOOLEAN NOT NULL DEFAULT FALSE,

    created_at DATETIME NOT NULL,

    updated_at DATETIME NULL,

    CONSTRAINT fk_event_organizer
        FOREIGN KEY (organizer_id)
        REFERENCES organizers(id)

);