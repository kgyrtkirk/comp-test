
-- \set dataset devices_1.csv
-- \set dataset devices_1.sql
-- \set table_name readings

\! pwd

\unset last_mode

\i devices_1.sql

\set current_mode normal
\i test1_int.sql
\set current_mode hyper
\i test1_int.sql
\set current_mode compressed
\i test1_int.sql



