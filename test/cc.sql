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
alter table main_table drop column battery_level;
call s_hyper();
-- call s_append();
-- call s_uncompress();
\d main_table

    ALTER TABLE main_table SET (timescaledb.compress,timescaledb.compress_segmentby = 'cpu_avg_5min',timescaledb.compress_orderby = 'rssi');
    select compress_chunk(show_chunks('main_table'));


--call s_compress();
-- call s_append();
-- call s_append();
-- call s_append();
-- call s_column_rename();
-- call s_column_rename();
-- call s_column_rename();
-- call s_column_rename();
-- call s_column_rename();
-- call s_column_rename();
-- call s_append();
-- call s_column_add_nullable();
-- call s_column_add_default();
-- call s_column_add_default();
-- call s_uncompress();
-- call s_compress();

\if :{?last_mode}

-- call compare(:'last_mode',:'current_mode');

\endif
