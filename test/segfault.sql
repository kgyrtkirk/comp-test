\i steps/hyper.sql
\i steps/append.sql
\i steps/uncompress.sql
\i steps/compress.sql
\i steps/append.sql
\i steps/rename_column.sql
\i steps/rename_column.sql
\i steps/rename_column.sql
\i steps/rename_column.sql
\i steps/rename_column.sql
\set step 10
-- \i steps/append.sql
\i steps/add_column_nullable.sql
\i steps/add_column_default.sql
\i steps/column_drop.sql
-- \i steps/uncompress.sql
\set step 13
\i steps/compress.sql
-- \i steps/append.sql
explain select count(1) over (partition by time,c),* from  :current_mode.readings c;
select count(1) over (partition by time,c),* from  :current_mode.readings c;