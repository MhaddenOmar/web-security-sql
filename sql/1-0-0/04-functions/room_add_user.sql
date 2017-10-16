CREATE OR REPLACE FUNCTION room_add_user(_user_id BIGINT, _room_id BIGINT)
RETURNS VOID



AS $$

BEGIN
    SET search_path=membership;

    INSERT INTO user_rooms (user_id,room_id) VALUES (_user_id,_room_id);

END;
$$
LANGUAGE PLPGSQL;