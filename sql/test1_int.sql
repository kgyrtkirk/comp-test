
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

 
select  :'current_mode' = 'normal' as t_normal,
        :'current_mode' = 'hyper' as t_hyper,
        :'current_mode' = 'compressed' as t_compressed
        \gset

\! pwd
\i load.sql
\i hyper.sql
\i append.sql
\i uncompress.sql
\i compress.sql
\i unhyper.sql
\i append.sql
\i hyper.sql
\i append.sql
\i uncompress.sql
\i compress.sql
\i append.sql

\i cmp.sql

\set last_mode :current_mode



