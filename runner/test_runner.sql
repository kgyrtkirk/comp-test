\set ON_ERROR_STOP 1
\set ON_ERROR_ROLLBACK 1

create or replace function load_timescaledb() returns void 
as
$$
declare
    installed integer;
begin
    select count(1) into installed from pg_extension where extname='timescaledb';
    set search_path=public;
    if installed < 1 then
        create extension timescaledb;
    end if;
end;
$$ language plpgsql;

select load_timescaledb();

\ir test_extensions.sql

\ir ../dataset/devices_1.sql

\unset last_mode
\set current_mode normal
\ir test_invoker.sql
\set current_mode hyper
\ir test_invoker.sql
\set current_mode compressed
\ir test_invoker.sql

\! banner ok

    -- set search_path=compressed,normal,hyper,public;