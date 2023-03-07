drop schema if exists :current_mode cascade;
create schema :current_mode;
set search_path=:current_mode,public;

select *,t_normal or t_hyper or t_compressed as ok from (
    select  :'current_mode' = 'normal' as t_normal,
            :'current_mode' = 'hyper' as t_hyper,
            :'current_mode' = 'compressed' as t_compressed
) t \gset

-- select :t_normal or :t_hyper or :t_compressed as ok \gset
\if :ok
\else
    DO $$ BEGIN RAISE EXCEPTION 'invalid mode: %',:'current_mode';END $$;
\endif

-- run the main test steps
\i load.sql
\i :test
\i cmp.sql

\set last_mode :current_mode
