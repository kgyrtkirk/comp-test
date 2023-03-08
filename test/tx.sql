
create view current_mode as select 

create table current_mode(mode text);
drop function if exists current_mode();
create or replace function current_mode()
returns text language plpgsql as $$
declare
    ret text;
    n integer;
begin
    select count(1) into n from current_mode;
    if n!=1 then
        raise EXCEPTION 'mode is not set correctly';
    end if;
    return ret;
end;
$$;
insert into 
select current_mode();

-- create table current_state(mode text, key text, value text);
-- create or replace function get_var(_key text)
-- returns text language sql as $$
--     select value from current_state where key=_key and mode=current_mode();
-- $$;



-- -- select get_var('asd');

-- -- set glb.user_not_found to -1;
-- -- set glb.user_not_found2 to glb.user_not_found;
-- -- set glb.user_does_not_have_permission to 'asd';

-- -- select glb('user_not_found'), glb('user_does_not_have_permission');

