
create or replace function is_hypertable(t_schema text, t_name text)  returns boolean 
language sql as 
$BODY$
select (select true from  timescaledb_information.hypertables where hypertable_schema =t_schema and hypertable_name=t_name) is true;
$BODY$;

select :'current_mode' != 'normal' AND NOT is_hypertable(:'current_mode',:'table_name') as proceed \gset

\if :proceed
    SELECT create_hypertable(:'table_name', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true);
\endif
