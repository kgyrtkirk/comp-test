
select :step+1 as step \gset

select setseed(1.0/(:step+1));

with t as (
select random() as r,column_name as column_name from hyper_columns
        where table_schema = :'current_mode' and table_name=:'table_name' and column_usage ='normal'
        group by column_name
)
select column_name as column_name from t order by column_name limit 1 \gset

select 'column_drop:' || :'column_name';
alter table :table_name drop column :column_name;
