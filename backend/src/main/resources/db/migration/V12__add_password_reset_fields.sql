    ALTER TABLE users
ADD COLUMN password_reset_token_hash VARCHAR(255),
ADD COLUMN password_reset_token_expires_at DATETIME,
ADD COLUMN password_reset_token_used BOOLEAN NOT NULL DEFAULT FALSE;