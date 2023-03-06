
select  :'current_mode' = 'normal' as t_normal,
        :'current_mode' = 'hyper' as t_hyper,
        :'current_mode' = 'compressed' as t_compressed
        \gset

\if :t_compressed
    select decompress_chunk(show_chunks(:'table_name'),true);

    select compress_chunk(show_chunks(:'table_name'),true);


-- create or replace function recompress_all(t_schema name,t_name name)
-- returns void as $$
-- DECLARE
--     chunk regclass;
-- BEGIN
--   FOR chunk IN SELECT format('%I.%I', chunk_schema, chunk_name)::regclass
--   FROM timescaledb_information.chunks
--   WHERE
--         is_compressed=true and 
--         hypertable_schema=t_schema AND hypertable_name=t_name
--   LOOP
--     RAISE NOTICE 'Recompressing %', chunk::text;
--     CALL recompress_chunk(chunk, true);
--   END LOOP;
-- END $$ language plpgsql;


-- select recompress_all(:'current_mode',:'table_name');

-- DO $$
-- DECLARE chunk regclass;
-- BEGIN
--   FOR chunk IN SELECT format('%I.%I', chunk_schema, chunk_name)::regclass
--   FROM timescaledb_information.chunks
--   WHERE is_compressed = true
--   LOOP
--     RAISE NOTICE 'Recompressing %', chunk::text;

--     CALL recompress_chunk(chunk::text, if_not_compressed => true);
--   END LOOP;
-- END
-- $$;



-- CALL recompress_chunk(readings, if_not_compressed => true);


\endif