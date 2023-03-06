\set ON_ERROR_STOP 1
\set ON_ERROR_ROLLBACK 1

select count(1) < 1 as not_installed from pg_extension where extname='timescaledb' \gset
\if :not_installed
    set search_path=public;
    create extension timescaledb;
\endif

show search_path;

\unset last_mode

\i devices_1.sql

-- \set current_mode normal
-- \i test1_int.sql
-- \set current_mode hyper
-- \i test1_int.sql
\set current_mode compressed
\set last_mode compressed
\i test1_int.sql

\! banner ok