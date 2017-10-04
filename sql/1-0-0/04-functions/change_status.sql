CREATE OR REPLACE FUNCTION change_status(_email VARCHAR,new_status_id INT,reason VARCHAR(50))
RETURNS user_summary
AS $$
DECLARE
    found_id BIGINT;
    user_record user_summary;
    status_name VARCHAR(50);
BEGIN
    SET search_path=membership;

    SELECT id FROM users WHERE users.email=_email INTO found_id;
    SELECT name FROM status WHERE id=new_status_id into status_name;

    IF(found_id IS NOT NULL)THEN

        -- RESET THE STATUS
        UPDATE users set status_id=new_status_id where id=found_id;

       

        -- ADD A NOTE
        INSERT INTO notes(user_id,note) VALUES (found_id,'Your status was changed to ' || status_name);

        -- ADD LOG
        INSERT INTO logs(user_id,subject,entry) VALUES (found_id,'System','Changed status to ' || status_name || ' because ' || reason);
    END IF;

    --PULL THE USER
    user_record:= get_user(_email);

    RETURN user_record;

END;
$$
LANGUAGE PLPGSQL;