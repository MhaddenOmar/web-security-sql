CREATE OR REPLACE FUNCTION can_authenticate(_email VARCHAR,_ip VARCHAR)

RETURNS TABLE(
    can_login BOOLEAN,
    message VARCHAR(100)
)
as $$

DECLARE    
    current_login_status membership.login_status;
    message VARCHAR(50) DEFAULT NULL;
    login_id VARCHAR DEFAULT concat(_ip,_email);
    found_id BIGINT;
    can_login BOOLEAN;

BEGIN
    SET search_path=membership;
    -- SEE IF USER IS ALLOWED TO LOG IN
        
    SELECT * from login_status where login_id = id into current_login_status;

    SELECT id from users where _email = email into found_id;
    
    IF(current_login_status IS NULL OR current_login_status.failed_attempts < 5)THEN
        can_login := true;    

    ELSIF((current_login_status.timeout + '10 second'::interval) <= now()) THEN
        DELETE FROM login_status WHERE id = login_id;
        can_login := true;

    ELSE    
        can_login := false;
        message := 'Account temporarly locked out';
        UPDATE login_status SET  in_progress=false WHERE current_login_status.id=login_id;

        IF(found_id IS NOT NULL) THEN
            INSERT INTO logs(user_id,subject,entry) VALUES (found_id,'Authentication', 'Account locked us ip : ' || _ip);
        END IF;


    END IF;        

    -- SEE IF LOGIN IS ALREADY IN PROGRESS

    IF(current_login_status.in_progress IS TRUE) THEN
        can_login := false;
        message := 'Cannot login, try again';
        
        IF(found_id IS NOT NULL) THEN
            INSERT INTO logs(user_id,subject,entry) VALUES (found_id,'Authentication', 'Tried to login while in progress');
        END IF;
    END IF;

    RETURN query
    SELECT can_login, message;

END;
$$
LANGUAGE PLPGSQL;