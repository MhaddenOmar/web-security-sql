CREATE TABLE room_resource(
    room_id  BIGINT NOT NULL PRIMARY KEY,
    id BIGINT NOT NULL DEFAULT id_generator(),
    resource_path VARCHAR(255),
    name VARCHAR(255)
);    
    
    