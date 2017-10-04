CREATE extension IF NOT EXISTS pgcrypto WITH SCHEMA membership;

CREATE OR REPLACE FUNCTION random_string(len int default 36)
returns text
as $$
select substring(md5(random()::text),0,len +1);

$$
LANGUAGE SQL;