CREATE OR REPLACE FUNCTION create_room_resource(_room_id BIGINT, _resource_path VARCHAR, _resource_name VARCHAR)
RETURNS VOID
as $$

BEGIN
    INSERT INTO membership.room_resource (room_id,resource_path,name) VALUES (_room_id,_resource_path,_resource_name);
END;

$$
LANGUAGE PLPGSQL;