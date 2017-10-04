CREATE OR REPLACE FUNCTION set_login_in_progress(_login_id VARCHAR,value BOOLEAN)
RETURNS VOID
as $$

DECLARE
return_in_progress BOOLEAN;

BEGIN
    SET search_path=membership;
    INSERT INTO login_status (id, in_progress) values (_login_id, value)
    ON CONFLICT (id) DO UPDATE SET in_progress =value;
    
END;
$$
LANGUAGE PLPGSQL;