-- Hi.Events Super Admin Account Creation Script
-- Creates two verified super admin accounts with no platform fees

-- First Super Admin: flynnduerrel@gmail.com
-- Second Super Admin: menganyidamarice@gmail.com

-- Create first account for flynnduerrel@gmail.com
INSERT INTO accounts (
    account_created_by_user_id,
    currency,
    timezone,
    account_verified_at,
    created_at,
    updated_at
) VALUES (
    NULL,
    'USD',
    'America/New_York',
    NOW(),
    NOW(),
    NOW()
) RETURNING id AS account_1_id;

-- Store the account ID from above query result and use it below as {ACCOUNT_1_ID}

-- Create first user (flynnduerrel@gmail.com)
INSERT INTO users (
    email,
    first_name,
    last_name,
    password,
    email_verified_at,
    created_at,
    updated_at
) VALUES (
    'flynnduerrel@gmail.com',
    'Flynn',
    'Duerrel',
    '$2y$12$aBcDeFgHiJkLmNoPqRsTuVwXyZ1A2B3C4D5E6F7G8H9I0J1K2L3M4N5', -- bcrypt hash (change as needed)
    NOW(),
    NOW(),
    NOW()
) RETURNING id AS user_1_id;

-- Create account_user relationship (flynnduerrel@gmail.com as SUPERADMIN)
-- Note: Replace {ACCOUNT_1_ID} and {USER_1_ID} with actual IDs from above queries
INSERT INTO account_user (
    account_id,
    user_id,
    role,
    created_at,
    updated_at
) VALUES (
    {ACCOUNT_1_ID},
    {USER_1_ID},
    'SUPERADMIN',
    NOW(),
    NOW()
);

-- Create second account for menganyidamarice@gmail.com
INSERT INTO accounts (
    account_created_by_user_id,
    currency,
    timezone,
    account_verified_at,
    created_at,
    updated_at
) VALUES (
    NULL,
    'USD',
    'America/New_York',
    NOW(),
    NOW(),
    NOW()
) RETURNING id AS account_2_id;

-- Create second user (menganyidamarice@gmail.com)
INSERT INTO users (
    email,
    first_name,
    last_name,
    password,
    email_verified_at,
    created_at,
    updated_at
) VALUES (
    'menganyidamarice@gmail.com',
    'Menganyi',
    'Damarice',
    '$2y$12$aBcDeFgHiJkLmNoPqRsTuVwXyZ1A2B3C4D5E6F7G8H9I0J1K2L3M4N5', -- bcrypt hash (change as needed)
    NOW(),
    NOW(),
    NOW()
) RETURNING id AS user_2_id;

-- Create account_user relationship (menganyidamarice@gmail.com as SUPERADMIN)
-- Note: Replace {ACCOUNT_2_ID} and {USER_2_ID} with actual IDs from above queries
INSERT INTO account_user (
    account_id,
    user_id,
    role,
    created_at,
    updated_at
) VALUES (
    {ACCOUNT_2_ID},
    {USER_2_ID},
    'SUPERADMIN',
    NOW(),
    NOW()
);

-- Optional: Create organizer configurations with zero fees
INSERT INTO organizer_configurations (
    account_id,
    created_at,
    updated_at
) VALUES 
    ({ACCOUNT_1_ID}, NOW(), NOW()),
    ({ACCOUNT_2_ID}, NOW(), NOW());
