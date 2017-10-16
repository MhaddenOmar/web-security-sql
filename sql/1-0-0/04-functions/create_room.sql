CREATE OR REPLACE FUNCTION create_room(_name VARCHAR)
RETURNS VOID


AS $$

BEGIN
    SET search_path=membership;

    INSERT INTO rooms (name) VALUES (_name);

END;
$$


LANGUAGE PLPGSQL;