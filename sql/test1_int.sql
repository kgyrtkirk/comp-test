
drop schema if exists :current_mode cascade;
create schema :current_mode;
set search_path=:current_mode,public;


create or replace function is_hypertable(t_schema text, t_name text)  returns boolean 
language sql as 
$BODY$
select (select true from  timescaledb_information.hypertables where hypertable_schema =t_schema and hypertable_name=t_name) is true;
$BODY$;

create or replace function is_compressed(t_schema text, t_name text)  returns boolean 
language sql as 
$BODY$
select (select compression_enabled from  timescaledb_information.hypertables where hypertable_schema =t_schema and hypertable_name=t_name) is true;
$BODY$;

drop view if exists hyper_columns;
create view hyper_columns as 
    select  i.table_schema,
            i.table_name,
            i.column_name,
            ti.dimension_number,
            segmentby_column_index,
            orderby_column_index,
            case
                when dimension_number is not null then 'dimension'
                when segmentby_column_index is not null then 'segmentby'
                when orderby_column_index is not null then 'orderby'
                else 'normal'
            end as column_usage
    from information_schema.columns i
        left outer join timescaledb_information.dimensions ti on (i.table_name = ti.hypertable_name and i.table_schema = ti.hypertable_schema and i.column_name = ti. column_name)
        left outer join timescaledb_information.compression_settings cs on (i.table_name = cs.hypertable_name and i.table_schema = cs.hypertable_schema and i.column_name = cs.attname)
;



select  :'current_mode' = 'normal' as t_normal,
        :'current_mode' = 'hyper' as t_hyper,
        :'current_mode' = 'compressed' as t_compressed
        \gset

\i load.sql
\i hyper.sql
\i append.sql
\i uncompress.sql
\i compress.sql
\i delete.sql
\i rename_column.sql
\i rename_column.sql
\i rename_column.sql
\i rename_column.sql
\i rename_column.sql
\i unhyper.sql
\i append.sql
\i hyper.sql
\i append.sql
\i add_column_nullable.sql
\i add_column_default.sql
\i column_drop.sql
\i uncompress.sql
\i compress.sql
\i rename_column.sql
\i append.sql
\i uncompress.sql

\i cmp.sql

\set last_mode :current_mode



