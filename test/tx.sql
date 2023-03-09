
drop function if exists current_mode();

create or replace function load(mode text) returns text language plpgsql volatile as $$ declare 
    _mode text;
begin
    -- mode=current_mode();
    perform format('drop schema if exists %s cascade',mode);
    perform format('create schema %s',mode);
    perform format('set search_path=%s,public',mode);
    perform format('create view current_mode as select %s',mode);

    create table current_state(
        mode text, key text, value text,
        UNIQUE(mode,key)
    );

    raise notice 'TODO: use perform/etc here?';
    create table main_table as select * from devices_1.readings;
    return mode;
end
$$;

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

create or replace function set_var(_key text,_value text)
returns void language plpgsql volatile as $$
declare 
    val text;
begin
    insert into current_state values (current_mode(), _key,_value)
    on conflict(mode,key)
    do update set value=excluded.value;
end
$$;

create or replace function hyper() returns text language plpgsql volatile as $$ declare 
    mode text;
begin
    mode=current_mode();
    if mode != 'normal' AND NOT is_hypertable(mode,'main_table') then
        return create_hypertable('main_table', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true);
    end if;
    return mode;
end
$$;

create or replace function unhyper() returns text language plpgsql volatile as $$ declare 
    mode text;
begin
    mode=current_mode();
    if is_hypertable(mode,'main_table') then
        -- https://stackoverflow.com/questions/57910070/convert-hypertable-to-regular-postgres-table
        CREATE TABLE normal_table (LIKE main_table INCLUDING ALL);
        INSERT INTO normal_table (SELECT * FROM main_table);
        DROP TABLE main_table; -- drops hypertable
        ALTER TABLE normal_table RENAME TO main_table;
    end if;
    return 'unhyper';
end
$$;




-- select :step+1 as step \gset

-- select :'current_mode' != 'normal' AND NOT is_hypertable(:'current_mode',:'table_name') as proceed \gset

-- \if :proceed
--     SELECT create_hypertable(:'table_name', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true);
-- \endif


select load('normal');
select current_mode();
select set_var('asd','1234');
select set_var('asd','123');
select get_var('asd');
select set_var('table_name','readings');
select set_var('source_schema','devices_1');

select hyper();
select unhyper();




-- drop schema if exists :current_mode cascade;
-- create schema :current_mode;
-- set search_path=:current_mode,public;

-- select *,t_normal or t_hyper or t_compressed as ok from (
--     select  :'current_mode' = 'normal' as t_normal,
--             :'current_mode' = 'hyper' as t_hyper,
--             :'current_mode' = 'compressed' as t_compressed
-- ) t \gset

-- -- select :t_normal or :t_hyper or :t_compressed as ok \gset
-- \if :ok
-- \else
--     DO $$ BEGIN RAISE EXCEPTION 'invalid mode: %',:'current_mode';END $$;
-- \endif

-- -- run the main test steps
-- \ir load.sql
-- \i test/:test
-- \ir cmp.sql

-- \set last_mode :current_mode
