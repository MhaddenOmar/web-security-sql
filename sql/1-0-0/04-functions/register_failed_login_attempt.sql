CREATE OR REPLACE FUNCTION register_failed_login_attempt(_login_id VARCHAR)
RETURNS VOID
AS $$

DECLARE
    return_login_status membership.login_status;

BEGIN
    SET search_path=membership;

    UPDATE login_status SET timeout = now(),failed_attempts = failed_attempts + 1  WHERE id = _login_id RETURNING * INTO return_login_status;
    
END;
$$
LANGUAGE PLPGSQL;