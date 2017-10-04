CREATE TABLE logs(
    id SERIAL PRIMARY KEY,
    subject log_type,
    user_id BIGINT,
    entry TEXT NOT NULL,
    data jsonb,
    created_at timestamptz DEFAULT now()
);