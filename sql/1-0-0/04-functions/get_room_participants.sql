CREATE OR REPLACE FUNCTION get_room_participants(_id BIGINT)
RETURNS TABLE(
    phone_nr VARCHAR(255),
    email VARCHAR(255),
    first VARCHAR(30),
    last VARCHAR(30)
)
AS $$
DECLARE
    found_users membership.users;    
BEGIN
    SET search_path=membership;

    return query    
    SELECT users.phone_nr,users.email,users.first,users.last FROM users
        INNER JOIN user_rooms ON user_rooms.user_id = users.id 
        WHERE user_rooms.room_id = _id;


END;
$$


LANGUAGE PLPGSQL;