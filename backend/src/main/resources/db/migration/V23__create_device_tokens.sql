CREATE TABLE device_tokens (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(30),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL,
    last_used_at DATETIME NULL,

    PRIMARY KEY (id),

    CONSTRAINT uk_device_token
        UNIQUE (token),

    CONSTRAINT fk_device_token_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
);