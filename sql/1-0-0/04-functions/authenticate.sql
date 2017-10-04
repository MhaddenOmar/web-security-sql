CREATE OR REPLACE FUNCTION authenticate(key VARCHAR,token VARCHAR,_ip VARCHAR DEFAULT '',prov VARCHAR DEFAULT 'local')  

RETURNS TABLE(
    return_id BIGINT,
    email VARCHAR(255),
    display_name VARCHAR(50),
    success BOOLEAN,
    message VARCHAR(50)
) as $$

DECLARE
    found_user membership.users;    
    return_message VARCHAR(50);
    success BOOLEAN;
    found_id BIGINT;   
    can_login BOOLEAN; 
    login_id VARCHAR DEFAULT concat(_ip,key);
    in_progress BOOLEAN;

BEGIN
    SET search_path=membership;


    -- SEE IF ALLOWED TO AUTHENTICATE
    SELECT can_authenticate.can_login,can_authenticate.message FROM can_authenticate(key,_ip) INTO can_login,return_message;

    IF(can_login IS FALSE) THEN

        success:= FALSE;

        RETURN query
        SELECT found_id, found_user.email, display_name, success, return_message;

    ELSE     
        -- SET LOGIN IN PROGRES FOR THE CURRENT LOGIN IN login_status
        PERFORM set_login_in_progress(login_id,true);

        -- FIND THE USER BY TOKEN/PROVIDER AND KEY    
        IF(prov = 'local')THEN
            SELECT locate_user_by_password(key,token) into found_id;
        ELSE
            SELECT user_id FROM logins where provider = prov AND provider_key = key AND provider_token = token into found_id;
        END IF;

        

        IF(found_id IS NOT NULL)THEN

            SELECT * FROM users WHERE users.id = found_id into found_user;

            SELECT status.can_login from status where id=found_user.status_id into can_login;
                                    
            IF(can_login) THEN                    

                -- LOG IT
                INSERT INTO logs(user_id,subject,entry) VALUES (found_id,'Authentication', 'Logged user is using' || prov);

                -- SET LAST LOGIN
                UPDATE users SET last_login=now(), login_count=login_count+1 WHERE users.id=found_id;

                -- SET DISPLAY NAME
                IF(found_user.first IS NOT NULL) THEN
                    SELECT concat(found_user.first, ' ', found_user.last )
                    into display_name;  
                ELSE
                    display_name = found_user.email;
                END IF;
                -- DELTE ATTMEPTED LOGINS FROM loing_status
                DELETE FROM login_status WHERE id = login_id;

                success := true;
                return_message := 'Logged in successful';
            ELSE

                -- log failed attempt
                
                INSERT INTO logs(user_id,subject,entry) VALUES (found_id,'Authentication','User tried to login, is locked out');

                -- REGISTER FAILED LOGIN ATTEMP IN login_status

                PERFORM register_failed_login_attempt(login_id);

                success := false;
                return_message := 'Account currently locked out';            
            END IF;
        ELSE               

            -- log failed attempt
                
                INSERT INTO logs(user_id,subject,entry) VALUES (found_id,'Authentication','User failed login with wrong credentials');

            -- REGISTER FAILED LOGIN ATTEMP IN login_status

            PERFORM register_failed_login_attempt(login_id);

            success := false;
            return_message := 'Invalid login credentials';
        END IF;         
        RETURN query
        SELECT found_id, found_user.email, display_name, success, return_message;
    END IF;            
END;

$$
LANGUAGE PLPGSQL;