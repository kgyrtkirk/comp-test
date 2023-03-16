\i steps/hyper.sql
\i steps/compress.sql
\set step 7
\i steps/rename_column.sql
\set step 10
\i steps/column_drop.sql
\set step 13
explain select count(1) over (partition by time,c),* from  :current_mode.readings c;
select count(1) over (partition by time,c),* from  :current_mode.readings c;