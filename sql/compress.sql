
select  :'current_mode' = 'compressed'
    AND is_hypertable(:'current_mode',:'table_name')
    AND NOT is_compressed(:'current_mode',:'table_name') as proceed \gset

\if :proceed
    ALTER TABLE :table_name SET (timescaledb.compress,timescaledb.compress_segmentby = 'device_id, rssi',timescaledb.compress_orderby = 'battery_status');
    select compress_chunk(show_chunks(:'table_name'));
\endif
