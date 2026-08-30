-- activation_token_expires_at already exists in users table.
-- No database change required in this migration.ALTER TABLE users
ADD COLUMN activation_token_expires_at TIMESTAMP NULL;