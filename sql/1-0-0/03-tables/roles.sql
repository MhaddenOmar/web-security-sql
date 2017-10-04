CREATE TABLE roles(
    id INT unique NOT NULL,
    description VARCHAR(25)
);

INSERT INTO roles values(10,'Administrator');
INSERT INTO roles values(99,'User');