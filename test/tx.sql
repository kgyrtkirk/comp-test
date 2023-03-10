
set search_path=public;

drop table if exists current_mode;

create or replace function current_mode()
returns text language sql as $$
    select current_setting('g.mode')
$$;

create or replace function get_var2(key text)
returns text language sql as $$
    select current_setting('g.'|| key)
$$;

create or replace procedure set_var2(key text,value text)
 language sql as $$
    select set_config('g.'|| key,value,false)
$$;

create or replace procedure load(mode text) language plpgsql as $$ declare 
    _mode text;
begin
    raise notice 'load: start';
    if mode not in ('hyper','normal','compressed') then
        raise EXCEPTION 'unknown mode: %', mode;
    end if;

    execute format('drop schema if exists %s cascade',mode);
    execute format('create schema %s',mode);
    execute format('set search_path=%s,public',mode);
    perform set_config('g.mode',mode,false);
    call set_var2('step_idx','0');
    -- perform format('create view current_mode as select %s',mode);


    -- set g.mode=asd;
    -- perform format('set my.mode=\'%s\'',mode);
    create table current_state(
        mode text, key text, value text,
        UNIQUE(mode,key)
    );

    raise notice 'TODO: use perform/etc here?';
    create table main_table as select * from devices_1.readings;
    raise notice 'load: end';
end
$$;

create or replace function get_var_t(_key text)
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

create or replace function set_var_t(_key text,_value text)
returns void language plpgsql volatile as $$
declare 
    val text;
begin
    insert into current_state values (current_mode(), _key,_value)
    on conflict(mode,key)
    do update set value=excluded.value;
end
$$;

-- drop function s_hyper();
create or replace procedure s_hyper() language plpgsql as $$ declare 
    mode text;
    msg text;
begin
    mode=current_mode();
    if mode != 'normal' AND NOT is_hypertable(mode,'main_table') then
        select create_hypertable('main_table', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true) into msg;
        raise notice 'create_hypertable: %',msg;
    end if;
end
$$;

create or replace function s_unhyper() returns text language plpgsql volatile as $$ declare 
    mode text;
begin
    mode=current_mode();
    if is_hypertable(mode,'main_table') then
        -- https://stackoverflow.com/questions/57910070/convert-hypertable-to-regular-postgres-table
        start transaction;
        CREATE TABLE normal_table (LIKE main_table INCLUDING ALL);
        INSERT INTO normal_table (SELECT * FROM main_table);
        DROP TABLE main_table; -- drops hypertable
        ALTER TABLE normal_table RENAME TO main_table;
        commit;
    end if;
    return 'unhyper';
end
$$;


create or replace procedure s_append() language plpgsql as $$ declare 
    mode text;
    ratio text;
    step_idx text;
begin
    mode=current_mode();
    step_idx=get_var2('step_idx');
    ratio='1';
        -- start transaction;
    create temporary  table stage as
        select * from devices_1.readings
            where md5(extract(epoch from time)::text || step_idx) < ratio;

    -- push records into the future
    update stage set time = time + ((select max(time) from main_table) - (select min(time) from stage)) + INTERVAL '1 us' + INTERVAL '1 day';

    insert into main_table select * from stage;

    drop table stage;
    -- commit;
end
$$;

create or replace procedure s_uncompress() language plpgsql as $$ declare 
    mode text;
begin
    mode=current_mode();
    if is_compressed(mode,'main_table') then
        perform decompress_chunk(show_chunks('main_table'),true);
        ALTER TABLE main_table SET (timescaledb.compress=false);
    end if;
end
$$;

create or replace procedure s_compress() language plpgsql as $$ declare 
    mode text;
    step_idx integer;
    p_segmentby float=.17;
    p_orderby float=.13;
    compress_options record;
begin
    mode=current_mode();
    step_idx=get_var2('step_idx');


    if  mode = 'compressed' 
    AND is_hypertable(mode,'main_table')
    AND NOT is_compressed(mode,'main_table') then

    execute setseed(1.0/(step_idx+1));
    with g as (
        select column_name from hyper_columns
            where table_schema = mode and table_name='main_table' and column_usage ='normal'
        order by column_name
    ),
    h as (select random() v,column_name from g)
    select 
        (select coalesce(string_agg(column_name,','),'') from h where v<p_segmentby) as segmentby,
        (select coalesce(string_agg(column_name,','),'') from h where v between p_segmentby and p_segmentby + p_orderby) as orderby
            into compress_options;

    raise notice 'compress options: segmentby=% , orderby=% ',compress_options.segmentby,compress_options.orderby;

    execute format('
        ALTER TABLE main_table SET (
            timescaledb.compress,
            timescaledb.compress_segmentby = ''%s'',
            timescaledb.compress_orderby = ''%s'')',compress_options.segmentby,compress_options.orderby);

        perform compress_chunk(show_chunks('main_table'));
    end if;

end
$$;

drop  function if exists step_state(name text);
-- create or replace function step_state(name text) returns table  ( mode text,step_idx integer) language plpgsql as $$
create or replace function step_state(name text) returns record language plpgsql as $$
declare
    ret record;
    step integer;
begin
    step=get_var2('step_idx')::integer + 1;
    call set_var2('step_idx',step::text);
    select current_mode() as mode,step as step_idx into ret;
    raise notice 'asd %',ret;
    return ret;
end
$$
;

create or replace procedure s_column_rename() language plpgsql as $$ declare 
    state record;
    col text;
begin
    -- select (step_state('column_rename')) into state;
    select * into state from step_state('column_rename') as f(mode text,step_idx integer);

    perform setseed(1.0/(state.step_idx));

    select column_name into col from hyper_columns
        where table_schema = state.mode and table_name='main_table' -- and column_usage ='normal'
        order by random() limit 1;

    execute format('alter table main_table rename %s to new_col_%s',col,state.step_idx);

end
$$;



create or replace procedure s_column_add_nullable() language plpgsql as $$ declare 
    state record;
    col text;
begin
    select * into state from step_state('column_rename') as f(mode text,step_idx integer);
    execute format('alter table main_table add column new_col_%s integer',state.step_idx);
end
$$;

create or replace procedure s_column_add_default() language plpgsql as $$ declare 
    state record;
    col text;
begin
    select * into state from step_state('column_rename') as f(mode text,step_idx integer);
    execute format('alter table main_table add column new_col_%s integer not null default %s',state.step_idx,state.step_idx);
end
$$;


-- select :step+1 as step \gset

-- select :'current_mode' != 'normal' AND NOT is_hypertable(:'current_mode',:'table_name') as proceed \gset

-- \if :proceed
--     SELECT create_hypertable(:'table_name', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true);
-- \endif


call load(:'current_mode');
-- select load('normal');
select :'current_mode';
select current_mode();
-- select * from current_mode;
-- select set_var('asd','1234');
-- select set_var('asd','123');
-- select get_var('asd');
-- select set_var('table_name','readings');
-- select set_var('source_schema','devices_1');
-- select get_var('table_name');
call s_hyper();
call s_append();
call s_uncompress();
call s_compress();
call s_append();
call s_append();
call s_append();
call s_column_rename();
call s_column_rename();
call s_column_rename();
call s_column_rename();
call s_column_rename();
call s_column_rename();
call s_append();
call s_column_add_nullable();
call s_column_add_default();
call s_column_add_default();
call s_uncompress();
call s_compress();

-- \i steps/append.sql
-- \set step 11
-- \i steps/column_add_nullable.sql
-- \i steps/column_add_default.sql
-- \i steps/uncompress.sql
-- \i steps/compress.sql


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
