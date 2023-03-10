

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

\if :{?last_mode}

call compare(:'last_mode',:'current_mode');

\endif

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
