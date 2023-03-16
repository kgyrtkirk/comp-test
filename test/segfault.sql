\i steps/hyper.sql
\i steps/compress.sql
alter table :current_mode.readings drop column battery_status;
explain select count(1) over (partition by time,c),* from  :current_mode.readings c;
select count(1) over (partition by time,c),* from  :current_mode.readings c;