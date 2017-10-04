CREATE OR REPLACE FUNCTION suspend_user(_email VARCHAR,reason VARCHAR(50))
RETURNS user_summary
AS $$
BEGIN
    SET search_path=membership;
    RETURN (
    SELECT change_status(_email,20,reason))::user_summary;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION lock_user(_email VARCHAR,reason VARCHAR(50))
RETURNS user_summary
AS $$
BEGIN
    SET search_path=membership;
    RETURN (
    SELECT change_status(_email,88,reason))::user_summary;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION ban_user(_email VARCHAR,reason VARCHAR(50))
RETURNS user_summary
AS $$
BEGIN
    SET search_path=membership;
    RETURN (
    SELECT change_status(_email,99,reason))::user_summary;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION activate_user(_email VARCHAR,reason VARCHAR(50))
RETURNS user_summary
AS $$
BEGIN
    SET search_path=membership;
    RETURN (
    SELECT change_status(_email,10,reason))::user_summary;
END;
$$
LANGUAGE PLPGSQL;