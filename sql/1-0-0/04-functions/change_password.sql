CREATE OR REPLACE FUNCTION change_password(_email VARCHAR,old_password VARCHAR,new_password VARCHAR)
RETURNS user_summary
AS $$

DECLARE found_id BIGINT;

BEGIN
    SET search_path=membership;

    -- FIND USER IN DB BASED ON EMAIL/PASSWORD
    SELECT locate_user_by_password(_email,old_password) into found_id;

    IF(found_id IS NOT NULL)THEN
        
        -- CHANGE IF PASSWORD IF OKAY
        UPDATE logins set provider_token = crypt(new_password,gen_salt('bf',10)) where user_id=found_id and provider='local';

        -- LOG IT
        INSERT INTO logs(user_id,subject,entry) VALUES (found_id,'Authentication', 'Password Changed');

        -- ADD A NOTE TO THE ACCOUNT

        INSERT INTO notes(user_id,note) VALUES (found_id,'Successfully changed password ');
    END IF;

    return get_user(_email);

END;
$$
LANGUAGE PLPGSQL;