\set ON_ERROR_STOP 1
\set ON_ERROR_ROLLBACK 1

-- create or replace function load_timescaledb() returns void 
-- as
-- $$
-- declare
--     installed integer;
-- begin
--     select count(1) into installed from pg_extension where extname='timescaledb';
--     set search_path=public;
--     if installed < 1 then
--         create extension timescaledb;
--     end if;
-- end;
-- $$ language plpgsql;

-- select load_timescaledb();

select count(1) < 1 as not_installed from pg_extension where extname='timescaledb' \gset
\if :not_installed
    set search_path=public;
    create extension timescaledb;
\endif


\i devices_1.sql

\unset last_mode
\set current_mode normal
\i :test
\set current_mode hyper
\i :test
\set current_mode compressed
\i :test

\! banner ok