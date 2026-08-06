INSERT INTO users (
    name,
    email,
    password,
    phone_number,
    role,
    status,
    created_at,
    first_login
)
VALUES (
    'System Admin',
    'admin@campussync.com',
    '$2a$10$2vRQITWte1kt..RMfTHC2eSxT9QtJ73GAXn2o4cB.sjmdTEZqit9y',
    '9999999999',
    'ADMIN',
    'ACTIVE',
    NOW(),
    FALSE
);