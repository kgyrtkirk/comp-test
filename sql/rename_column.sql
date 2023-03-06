
select :step+1 as step \gset

select setseed(1.0/(:step+1));

select column_name as column_name from hyper_columns
        where table_schema = :'current_mode' and table_name=:'table_name' -- and column_usage ='normal'
        order by random() limit 1 \gset

alter table :table_name rename :column_name to new_col_:step;
