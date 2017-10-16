set search_path=membership;
drop schema if exists membership CASCADE;

create schema membership;
set search_path = membership;

select 'Schema initialized' as result;
-- timstamp (41) | shardid(13) | userid(10)
SET search_path = membership;
CREATE SEQUENCE id_sequence;    
CREATE OR REPLACE FUNCTION id_generator(out new_id BIGINT)

as $$

DECLARE
    our_epoch BIGINT := 814904585000;  -- my bday in ms
    seq_id BIGINT;
    now_ms BIGINT;
    shard_id int:= 1;

BEGIN 
    SELECT NEXTVAL('id_sequence') %1024 INTO seq_id; 
    SELECT FLOOR(EXTRACT(EPOCH FROM now()) * 1000) INTO now_ms;
    new_id := (now_ms - our_epoch) << 23; -- shift to 23 bits to the left to have 41 bits for our new_id
    new_id := new_id | (shard_id << 10);
    new_id := new_id | (seq_id);
END;


$$
LANGUAGE PLPGSQL;
CREATE extension IF NOT EXISTS pgcrypto WITH SCHEMA membership;

CREATE OR REPLACE FUNCTION random_string(len int default 36)
returns text
as $$
select substring(md5(random()::text),0,len +1);

$$
LANGUAGE SQL;
CREATE TYPE log_type AS ENUM(
    'Registration',
    'Authentication',
    'Activity',
    'System'
);
CREATE TYPE user_summary as (
    id BIGINT,
    email VARCHAR(250),
    status VARCHAR(50),
    can_login BOOLEAN,
    is_admin BOOLEAN,
    display_name VARCHAR(255),
    user_key VARCHAR(18),
    email_validation_token VARCHAR(36),
    user_for INTERVAL,
    -- profile JSONB,
    logs JSONB,
    notes JSONB
);
CREATE TABLE logins(
    id BIGINT PRIMARY KEY DEFAULT id_generator(),
    user_id BIGINT NOT NULL,
    provider VARCHAR(50) NOT NULL DEFAULT 'local',
    provider_key VARCHAR(255),
    provider_token VARCHAR(255) NOT NULL
);
CREATE TABLE login_status(
    id VARCHAR(100) NOT NULL PRIMARY KEY,
    failed_attempts INT NOT NULL DEFAULT 0,
    timeout TIMESTAMP NOT NULL DEFAULT now(),
    in_progress BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE TABLE logs(
    id SERIAL PRIMARY KEY,
    subject log_type,
    user_id BIGINT,
    entry TEXT NOT NULL,
    data jsonb,
    created_at timestamptz DEFAULT now()
);
CREATE TABLE notes(
    id BIGINT NOT NULL DEFAULT id_generator(),
    user_id BIGINT NOT NULL,
    note VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE TABLE roles(
    id INT unique NOT NULL,
    description VARCHAR(25)
);

INSERT INTO roles values(10,'Administrator');
INSERT INTO roles values(99,'User');
CREATE TABLE rooms(
    id BIGINT NOT NULL DEFAULT id_generator() PRIMARY KEY,
    name VARCHAR(255)
);
CREATE TABLE room_resource(
    room_id  BIGINT NOT NULL PRIMARY KEY,
    id BIGINT NOT NULL DEFAULT id_generator(),
    resource_path VARCHAR(255),
    name VARCHAR(255)
);    
    
    
CREATE TABLE status(
    id INT PRIMARY KEY NOT NULL,
    name VARCHAR(20),
    description VARCHAR(100),
    can_login BOOLEAN    
);

INSERT INTO status values(10,'Active','User can login, etc',TRUE);
INSERT INTO status values(20,'Suspended','Cannot login for a given reason',FALSE);
INSERT INTO status values(30,'Not Approved','Member need to be approved (email validation)',FALSE);
INSERT INTO status values(99,'Banned','Member has been banned',FALSE);
INSERT INTO status values(88,'Locked','Member is locked out due to failed logins',FALSE);
CREATE TABLE users(
 id BIGINT PRIMARY KEY NOT NULL DEFAULT id_generator(),
 user_key VARCHAR(36) DEFAULT random_string(18) NOT NULL,
 email varchar(255) unique not null,
 first VARCHAR(25),
 last VARCHAR(25),
 hashed_password VARCHAR(255),
 search tsvector, 
 created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
 status VARCHAR(10) DEFAULT 'active',
 validation_token VARCHAR(36),
 last_login TIMESTAMPTZ,
 login_count INT DEFAULT 0 NOT NULL,
 phone_nr VARCHAR(255),
 status_id INT 
);





CREATE TABLE user_roles(
    user_id BIGINT NOT NULL,
    role_id INT NOT NULL
);
CREATE TABLE user_rooms(
    user_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL
);
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
CREATE OR REPLACE FUNCTION create_room(_name VARCHAR)
RETURNS VOID


AS $$

BEGIN
    SET search_path=membership;

    INSERT INTO rooms (name) VALUES (_name);

END;
$$


LANGUAGE PLPGSQL;
CREATE OR REPLACE FUNCTION create_room_resource(_room_id BIGINT, _resource_path VARCHAR, _resource_name VARCHAR)
RETURNS VOID
as $$

BEGIN
    INSERT INTO membership.room_resource (room_id,resource_path,name) VALUES (_room_id,_resource_path,_resource_name);
END;

$$
LANGUAGE PLPGSQL;
-- CREATE OR REPLACE FUNCTION get_rooms()
-- RETURNS TABLE(
--     id BIGINT,
--     name VARCHAR(255)
-- )
-- AS $$    

-- BEGIN
--     SELECT rooms.id,rooms.name FROM rooms INTO id,name;

--     return query
--     SELECT id,name;
-- END;
-- $$
-- LANGUAGE PLPGSQL;


-- CREATE OR REPLACE FUNCTION get_rooms(_id BIGINT)
-- RETURNS rooms
-- AS $$

-- BEGIN
--     SELECT * from rooms
-- END;
-- $$
-- LANGUAGE PLPGSQL;
CREATE OR REPLACE FUNCTION get_room_participants(_id BIGINT)
RETURNS TABLE(
    phone_nr VARCHAR(255),
    email VARCHAR(255),
    first VARCHAR(30),
    last VARCHAR(30)
)
AS $$
DECLARE
    found_users membership.users;    
BEGIN
    SET search_path=membership;

    return query    
    SELECT users.phone_nr,users.email,users.first,users.last FROM users
        INNER JOIN user_rooms ON user_rooms.user_id = users.id 
        WHERE user_rooms.room_id = _id;


END;
$$


LANGUAGE PLPGSQL;
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
CREATE OR REPLACE FUNCTION room_add_user(_user_id BIGINT, _room_id BIGINT)
RETURNS VOID



AS $$

BEGIN
    SET search_path=membership;

    INSERT INTO user_rooms (user_id,room_id) VALUES (_user_id,_room_id);

END;
$$
LANGUAGE PLPGSQL;
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
ALTER TABLE logins
ADD CONSTRAINT logins_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE logs
ADD CONSTRAINT logs_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE users
ADD CONSTRAINT users_status
FOREIGN KEY (status_id) REFERENCES status(id)
ON DELETE CASCADE;

ALTER TABLE user_roles
ADD CONSTRAINT user_roles_roles
FOREIGN KEY (role_id) REFERENCES roles(id)
ON DELETE CASCADE;

ALTER TABLE user_roles
ADD CONSTRAINT user_roles_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE notes
ADD CONSTRAINT notes_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE user_rooms
ADD CONSTRAINT user_rooms_rooms
FOREIGN KEY (room_id) REFERENCES rooms(id)
ON DELETE CASCADE;

ALTER TABLE user_rooms
ADD CONSTRAINT user_rooms_users
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE room_resource
ADD CONSTRAINT room_resource_rooms
FOREIGN KEY (room_id) REFERENCES rooms(id)
ON DELETE CASCADE;