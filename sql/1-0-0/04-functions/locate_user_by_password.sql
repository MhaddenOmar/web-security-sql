CREATE OR REPLACE FUNCTION locate_user_by_password(_email VARCHAR,password VARCHAR)
RETURNS BIGINT
AS $$

BEGIN
    SET search_path=membership;

    RETURN (
    SELECT user_id FROM logins where provider = 'local' AND provider_key = _email AND provider_token = crypt(password,provider_token));
    
END;
$$
LANGUAGE PLPGSQL;