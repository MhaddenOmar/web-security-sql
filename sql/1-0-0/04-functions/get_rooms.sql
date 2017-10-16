-- CREATE OR REPLACE FUNCTION get_rooms()
-- RETURNS TABLE(
--     id BIGINT,
--     name VARCHAR(255)
-- )
-- AS $$    

-- BEGIN
--     SELECT rooms.id,rooms.name FROM rooms INTO id,name;

--     return query
--     SELECT id,name;
-- END;
-- $$
-- LANGUAGE PLPGSQL;


-- CREATE OR REPLACE FUNCTION get_rooms(_id BIGINT)
-- RETURNS rooms
-- AS $$

-- BEGIN
--     SELECT * from rooms
-- END;
-- $$
-- LANGUAGE PLPGSQL;