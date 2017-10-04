CREATE TABLE notes(
    id BIGINT NOT NULL DEFAULT id_generator(),
    user_id BIGINT NOT NULL,
    note VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);