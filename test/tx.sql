
create view current_mode as select 'normal';

drop function if exists current_mode();
create or replace function current_mode()
returns text language sql as $$
    select * from current_mode
$$;
select current_mode();

create table current_state(mode text, key text, value text);
create or replace function get_var(_key text)
returns text language plpgsql stable as $$
declare 
    val text;
begin
    select value into val from current_state where key=_key and mode=current_mode();
    if val is null then
        raise EXCEPTION 'Value of % is unknown!',_key;
    end if;
    return val;

end
$$;


create or replace function some1() returns text language plpgsql stable as $$ declare 
    val text;
begin
    select get_var('asd');

    -- select value into val from current_state where key=_key and mode=current_mode();
    -- if val is null then
    --     raise EXCEPTION 'Value of % is unknown!',_key;
    -- end if;
    -- return val;

end
$$;

select some1();


-- -- select get_var('asd');

-- -- set glb.user_not_found to -1;
-- -- set glb.user_not_found2 to glb.user_not_found;
-- -- set glb.user_does_not_have_permission to 'asd';

-- -- select glb('user_not_found'), glb('user_does_not_have_permission');

