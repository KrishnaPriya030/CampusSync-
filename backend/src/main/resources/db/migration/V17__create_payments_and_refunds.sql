CREATE TABLE payments (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    registration_id BIGINT NOT NULL UNIQUE,

    amount DECIMAL(10,2) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',

    razorpay_order_id VARCHAR(255) NULL UNIQUE,

    razorpay_payment_id VARCHAR(255) NULL,

    razorpay_signature VARCHAR(500) NULL,

    payment_reference VARCHAR(255) NULL,

    paid_at DATETIME NULL,

    created_at DATETIME NOT NULL,

    updated_at DATETIME NULL,

    CONSTRAINT fk_payment_registration
        FOREIGN KEY (registration_id)
        REFERENCES event_registrations(id)

);

CREATE TABLE refunds (

    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    payment_id BIGINT NOT NULL UNIQUE,

    amount DECIMAL(10,2) NOT NULL,

    reason TEXT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',

    requested_at DATETIME NOT NULL,

    processed_at DATETIME NULL,

    processing_note TEXT NULL,

    CONSTRAINT fk_refund_payment
        FOREIGN KEY (payment_id)
        REFERENCES payments(id)

);