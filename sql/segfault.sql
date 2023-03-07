
drop schema if exists :current_mode cascade;
create schema :current_mode;
set search_path=:current_mode,public;

select  :'current_mode' = 'normal' as t_normal,
        :'current_mode' = 'hyper' as t_hyper,
        :'current_mode' = 'compressed' as t_compressed
        \gset

\i load.sql
\i hyper.sql
\i append.sql
\i uncompress.sql
\i compress.sql
\i append.sql
-- \i delete.sql
\i rename_column.sql
\i rename_column.sql
\i rename_column.sql
\i rename_column.sql
\i rename_column.sql
-- \i unhyper.sql
\i append.sql
-- \i hyper.sql
-- \i append.sql
\i add_column_nullable.sql
\i add_column_default.sql
\i column_drop.sql
\i uncompress.sql
\i compress.sql
-- \i rename_column.sql
\i append.sql
-- \i uncompress.sql

\i cmp.sql

\set last_mode :current_mode



