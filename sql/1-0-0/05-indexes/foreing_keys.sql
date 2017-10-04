ALTER TABLE logins
ADD CONSTRAINT logins_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE logs
ADD CONSTRAINT logs_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE users
ADD CONSTRAINT users_status
FOREIGN KEY (status_id) REFERENCES status(id)
ON DELETE CASCADE;

ALTER TABLE user_roles
ADD CONSTRAINT user_roles_roles
FOREIGN KEY (role_id) REFERENCES roles(id)
ON DELETE CASCADE;

ALTER TABLE user_roles
ADD CONSTRAINT user_roles_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE notes
ADD CONSTRAINT notes_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;