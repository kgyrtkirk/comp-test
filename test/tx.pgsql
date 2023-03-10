SET search_path = public;

DROP TABLE IF EXISTS current_mode;

CREATE OR REPLACE FUNCTION current_mode ()
    RETURNS text
    LANGUAGE sql
    AS $$
    SELECT
        current_setting('g.mode')
$$;

CREATE OR REPLACE FUNCTION get_var2 (key text)
    RETURNS text
    LANGUAGE sql
    AS $$
    SELECT
        current_setting('g.' || key)
$$;

CREATE OR REPLACE PROCEDURE set_var2 (key text, value text)
LANGUAGE sql
AS $$
    SELECT
        set_config('g.' || key, value, FALSE)
$$;

CREATE OR REPLACE PROCEDURE LOAD (mode text)
LANGUAGE plpgsql
AS $$
DECLARE
    _mode text;
BEGIN
    RAISE NOTICE 'load: start';
    IF mode NOT IN ('hyper', 'normal', 'compressed') THEN
        RAISE EXCEPTION 'unknown mode: %', mode;
    END IF;
    EXECUTE format('drop schema if exists %s cascade', mode);
    EXECUTE format('create schema %s', mode);
    EXECUTE format('set search_path=%s,public', mode);
    PERFORM
        set_config('g.mode', mode, FALSE);
    CALL set_var2 ('step_idx', '0');
    -- perform format('create view current_mode as select %s',mode);
    -- set g.mode=asd;
    -- perform format('set my.mode=\'%s\'',mode);
    CREATE TABLE current_state (
        mode text,
        key text,
        value text,
        UNIQUE (mode, key )
    );
    RAISE NOTICE 'todo: use perform/etc here?';
    CREATE TABLE main_table AS
    SELECT
        *
    FROM
        devices_1.readings;
        RAISE NOTICE 'load: end';
END
$$;

CREATE OR REPLACE FUNCTION get_var_t (_key text)
    RETURNS text
    LANGUAGE plpgsql
    STABLE
    AS $$
DECLARE
    val text;
BEGIN
    SELECT
        value INTO val
    FROM
        current_state
    WHERE
        key = _key
        AND mode = current_mode ();
    IF val IS NULL THEN
        RAISE EXCEPTION 'value of % is unknown!', _key;
    END IF;
    RETURN val;
END
$$;

CREATE OR REPLACE FUNCTION set_var_t (_key text, _value text)
    RETURNS void
    LANGUAGE plpgsql
    VOLATILE
    AS $$
DECLARE
    val text;
BEGIN
    INSERT INTO current_state
        VALUES (current_mode (), _key, _value)
    ON CONFLICT (mode, key)
        DO UPDATE SET
            value = excluded.value;
END
$$;

-- drop function s_hyper();
CREATE OR REPLACE PROCEDURE s_hyper ()
LANGUAGE plpgsql
AS $$
DECLARE
    mode text;
    msg text;
BEGIN
    mode = current_mode ();
    IF mode != 'normal' AND NOT is_hypertable (mode, 'main_table') THEN
        SELECT
            create_hypertable ('main_table', 'time', chunk_time_interval => interval '12 hour', migrate_data => TRUE) INTO msg;
        RAISE NOTICE 'create_hypertable: %', msg;
    END IF;
END
$$;

CREATE OR REPLACE FUNCTION s_unhyper ()
    RETURNS text
    LANGUAGE plpgsql
    VOLATILE
    AS $$
DECLARE
    mode text;
BEGIN
    mode = current_mode ();
    IF is_hypertable (mode, 'main_table') THEN
        -- https://stackoverflow.com/questions/57910070/convert-hypertable-to-regular-postgres-table
        CREATE TABLE normal_table (
            LIKE main_table INCLUDING ALL
        );
    INSERT INTO normal_table (
        SELECT
            *
        FROM
            main_table);
    DROP TABLE main_table;
    ALTER TABLE normal_table RENAME TO main_table;
END IF;
    RETURN 'unhyper';
END
$$;

CREATE OR REPLACE PROCEDURE s_append ()
LANGUAGE plpgsql
AS $$
DECLARE
    mode text;
    ratio text;
    step_idx text;
BEGIN
    mode = current_mode ();
    step_idx = get_var2 ('step_idx');
    ratio = '1';
    CREATE TABLE stage AS
    SELECT
        *
    FROM
        main_table
    WHERE
        md5(extract(epoch FROM time)::text || step_idx) < ratio;
    -- push records into the future
    UPDATE
        stage
    SET
        time = time + (
            SELECT
                max(time) - min(time)
            FROM
                stage) + interval '1 us' + interval '1 day';
    INSERT INTO main_table
    SELECT
        *
    FROM
        stage;
    DROP TABLE stage;
END
$$;

CREATE OR REPLACE PROCEDURE s_uncompress ()
LANGUAGE plpgsql
AS $$
DECLARE
    mode text;
BEGIN
    mode = current_mode ();
    IF is_compressed (mode, 'main_table') THEN
        PERFORM
            decompress_chunk (show_chunks ('main_table'), TRUE);
        ALTER TABLE main_table SET (timescaledb.compress = FALSE);
    END IF;
END
$$;

CREATE OR REPLACE PROCEDURE s_compress ()
LANGUAGE plpgsql
AS $$
DECLARE
    mode text;
    step_idx integer;
    p_segmentby float =.17;
    p_orderby float =.13;
    compress_options record;
BEGIN
    mode = current_mode ();
    step_idx = get_var2 ('step_idx');
    IF mode = 'compressed' AND is_hypertable (mode, 'main_table') AND NOT is_compressed (mode, 'main_table') THEN
        EXECUTE setseed(1.0 / (step_idx + 1));
        WITH g AS (
            SELECT
                column_name
            FROM
                hyper_columns
            WHERE
                table_schema = mode
                AND table_name = 'main_table'
                AND column_usage = 'normal'
            ORDER BY
                column_name
),
h AS (
    SELECT
        random() v,
    column_name
FROM
    g
)
SELECT
    (
        SELECT
            coalesce(string_agg(column_name, ','), '')
        FROM
            h
        WHERE
            v < p_segmentby) AS segmentby,
    (
        SELECT
            coalesce(string_agg(column_name, ','), '')
        FROM
            h
        WHERE
            v BETWEEN p_segmentby AND p_segmentby + p_orderby) AS orderby INTO compress_options;
        RAISE NOTICE 'compress options: segmentby=% , orderby=% ', compress_options.segmentby, compress_options.orderby;
        EXECUTE format('
        alter table main_table set (
            timescaledb.compress,
            timescaledb.compress_segmentby = ''%s'',
            timescaledb.compress_orderby = ''%s'')', compress_options.segmentby, compress_options.orderby);
        PERFORM
            compress_chunk (show_chunks ('main_table'));
END IF;
END
$$;

DROP FUNCTION IF EXISTS step_state (name text);

-- create or replace function step_state(name text) returns table  ( mode text,step_idx integer) language plpgsql as $$
CREATE OR REPLACE FUNCTION step_state (name text)
    RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    ret record;
    step integer;
BEGIN
    step = get_var2 ('step_idx')::integer + 1;
    CALL set_var2 ('step_idx', step::text);
    SELECT
        current_mode () AS mode,
        step AS step_idx INTO ret;
    RAISE NOTICE 'asd %', ret;
    RETURN ret;
END
$$;

CREATE OR REPLACE PROCEDURE s_column_rename ()
LANGUAGE plpgsql
AS $$
DECLARE
    state record;
    col text;
BEGIN
    -- select (step_state('column_rename')) into state;
    SELECT
        * INTO state
    FROM
        step_state ('column_rename') AS f (mode text,
        step_idx integer);
    PERFORM
        setseed(1.0 / (state.step_idx));
    SELECT
        column_name INTO col
    FROM
        hyper_columns
    WHERE
        table_schema = state.mode
        AND table_name = 'main_table' -- and column_usage ='normal'
    ORDER BY
        random()
    LIMIT 1;
    EXECUTE format('alter table main_table rename %s to new_col_%s', col, state.step_idx);
END
$$;

CREATE OR REPLACE PROCEDURE s_column_add_nullable ()
LANGUAGE plpgsql
AS $$
DECLARE
    state record;
    col text;
BEGIN
    SELECT
        * INTO state
    FROM
        step_state ('column_rename') AS f (mode text,
        step_idx integer);
    EXECUTE format('alter table main_table add column new_col_%s integer', state.step_idx);
END
$$;

CREATE OR REPLACE PROCEDURE s_column_add_default ()
LANGUAGE plpgsql
AS $$
DECLARE
    state record;
    col text;
BEGIN
    SELECT
        * INTO state
    FROM
        step_state ('column_rename') AS f (mode text,
        step_idx integer);
    EXECUTE format('alter table main_table add column new_col_%s integer not null default %s', state.step_idx, state.step_idx);
END
$$;

-- select :step+1 as step \gset
-- select :'current_mode' != 'normal' and not is_hypertable(:'current_mode',:'table_name') as proceed \gset
-- \if :proceed
--     select create_hypertable(:'table_name', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true);
-- \endif
CALL LOAD (:'current_mode');

-- select load('normal');
SELECT
    :'current_mode';

SELECT
    current_mode ();

-- select * from current_mode;
-- select set_var('asd','1234');
-- select set_var('asd','123');
-- select get_var('asd');
-- select set_var('table_name','readings');
-- select set_var('source_schema','devices_1');
-- select get_var('table_name');
CALL s_hyper ();

CALL s_append ();

CALL s_uncompress ();

CALL s_compress ();

CALL s_append ();

CALL s_append ();

CALL s_append ();

CALL s_column_rename ();

CALL s_column_rename ();

CALL s_column_rename ();

CALL s_column_rename ();

CALL s_column_rename ();

CALL s_column_rename ();

CALL s_append ();

CALL s_column_add_nullable ();

CALL s_column_add_default ();

CALL s_column_add_default ();

CALL s_uncompress ();

CALL s_compress ();

-- \i steps/append.sql
-- \set step 11
-- \i steps/column_add_nullable.sql
-- \i steps/column_add_default.sql
-- \i steps/uncompress.sql
-- \i steps/compress.sql
-- drop schema if exists :current_mode cascade;
-- create schema :current_mode;
-- set search_path=:current_mode,public;
-- select *,t_normal or t_hyper or t_compressed as ok from (
--     select  :'current_mode' = 'normal' as t_normal,
--             :'current_mode' = 'hyper' as t_hyper,
--             :'current_mode' = 'compressed' as t_compressed
-- ) t \gset
-- -- select :t_normal or :t_hyper or :t_compressed as ok \gset
-- \if :ok
-- \else
--     do $$ begin raise exception 'invalid mode: %',:'current_mode';end $$;
-- \endif
-- -- run the main test steps
-- \ir load.sql
-- \i test/:test
-- \ir cmp.sql
-- \set last_mode :current_mode
