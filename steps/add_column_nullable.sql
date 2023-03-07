
select :step+1 as step \gset

alter table :table_name add column new_col_:step integer;
