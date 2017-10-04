CREATE OR REPLACE FUNCTION get_user(_email varchar)
RETURNS user_summary
AS $$
DECLARE
    dname VARCHAR(255):= _email;
    found_user users;
    member_for INTERVAL;
    can_login BOOLEAN;
    is_admin BOOLEAN;
    return_status VARCHAR(25);
    json_logs JSONB;
    json_notes JSONB;
    user_status membership.status;
BEGIN

    SET search_path=membership;

    -- USER EXISTS IN DB ?
    IF EXISTS (SELECT users.id FROM users WHERE users.email = _email) THEN
        SELECT * FROM users into found_user;

        -- DISPLAY NAME
        IF(found_user.first IS NOT NULL) THEN
            SELECT concat(found_user.first, ' ', found_user.last )
            into dname;        
        END IF;
        
        -- MEMBER FOR
        SELECT age(now(),found_user.created_at into member_for);

        -- STATUS
        select * from status where id=found_user.status_id into user_status;
        can_login:=user_status.can_login;
        return_status:=user_status.name;

        -- ADMIN
        SELECT EXISTS(SELECT user_id FROM user_roles WHERE user_id=found_user.id AND role_id=10) into is_admin;        

        -- LOGS
        select json_agg(x) into json_logs from (select * from logs where logs.user_id=found_user.id) x;

        -- notes
        select json_agg(y) into json_notes from (select * from notes where notes.user_id=found_user.id) y;

    END IF;

    RETURN (
        found_user.id,
        found_user.email,
        return_status,
        can_login,
        is_admin,
        dname,
        found_user.user_key,
        found_user.validation_token,
        member_for,
        json_logs,
        json_notes
    )::user_summary;    
END;
$$
LANGUAGE PLPGSQL;

