CREATE TABLE rooms(
    id BIGINT NOT NULL DEFAULT id_generator() PRIMARY KEY,
    name VARCHAR(255)
);