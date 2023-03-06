
select  :'current_mode' = 'compressed'
    AND is_compressed(:'current_mode',:'table_name') as proceed \gset

\if :proceed
    select decompress_chunk(show_chunks(:'table_name'),true);
    ALTER TABLE :table_name SET (timescaledb.compress=false);
\endif
