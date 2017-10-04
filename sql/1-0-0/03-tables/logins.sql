CREATE TABLE logins(
    id BIGINT PRIMARY KEY DEFAULT id_generator(),
    user_id BIGINT NOT NULL,
    provider VARCHAR(50) NOT NULL DEFAULT 'local',
    provider_key VARCHAR(255),
    provider_token VARCHAR(255) NOT NULL
);