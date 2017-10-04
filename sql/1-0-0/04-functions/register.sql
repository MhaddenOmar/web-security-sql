CREATE OR REPLACE FUNCTION register(_email VARCHAR,password VARCHAR,_first_name VARCHAR DEFAULT NULL,_last_name VARCHAR DEFAULT NULL)
RETURNS TABLE(
    new_id BIGINT,    
    validation_token VARCHAR(36),
    success BOOLEAN,
    message VARCHAR(255)
)AS $$
BEGIN
    SET search_path=membership;
    -- SEE IF EXISTS
    IF NOT EXISTS (SELECT users.email FROM users WHERE users.email = _email) THEN 

        validation_token := random_string(36);

        -- ADD USER 
        INSERT INTO users(email,status_id,validation_token,first,last) VALUES (_email,10,validation_token,_first_name,_last_name)
        RETURNING id into new_id;

        -- ADD LOGINS
        INSERT INTO logins(user_id,provider_key,provider_token) VALUES(new_id,_email,crypt(password, gen_salt('bf',10)));

        -- TOKEN LOGIN
        INSERT INTO logins(user_id,provider,provider_token) VALUES (new_id,'token',random_string(36));

        -- ADD TO USER_ROLES
        INSERT INTO user_roles(user_id,role_id) VALUES (new_id,'99');

        -- LOG IT
        INSERT INTO logs(user_id,subject,entry) VALUES (new_id,'Registration', 'User registered with email' || _email);
        

        success := true;
        message := 'User registered successfully';   
    ELSE    
        success := false;
        select 'This email is already registered' into message;
    END IF;

    -- return 
    RETURN query
    SELECT new_id, validation_token, success, message;

END;
$$
LANGUAGE PLPGSQL;