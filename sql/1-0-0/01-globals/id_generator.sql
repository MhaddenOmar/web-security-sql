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