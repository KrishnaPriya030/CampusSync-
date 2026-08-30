CREATE TABLE revoked_tokens (
    id BIGINT NOT NULL AUTO_INCREMENT,
    token_id VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME NOT NULL,
    PRIMARY KEY (id)
);