CREATE TABLE users(
 id BIGINT PRIMARY KEY NOT NULL DEFAULT id_generator(),
 user_key VARCHAR(36) DEFAULT random_string(18) NOT NULL,
 email varchar(255) unique not null,
 first VARCHAR(25),
 last VARCHAR(25),
 hashed_password VARCHAR(255),
 search tsvector, 
 created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
 status VARCHAR(10) DEFAULT 'active',
 validation_token VARCHAR(36),
 last_login TIMESTAMPTZ,
 login_count INT DEFAULT 0 NOT NULL,
 phone_nr VARCHAR(255),
 status_id INT 
);




