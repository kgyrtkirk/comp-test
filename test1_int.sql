
drop schema if exists :current_mode cascade;
create schema :current_mode;
set search_path=:current_mode,public;

\! pwd
\i load.sql
\i hyper.sql
\i append.sql
\i compress.sql
\i append.sql

\if :t_compressed
select _timescaledb_internal.chunk_status(show_chunks('readings'));
\endif
-- \i delete.sql
\i recompress.sql
\i cmp.sql

\set last_mode :current_mode



