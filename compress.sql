
select  :'current_mode' = 'normal' as t_normal,
        :'current_mode' = 'hyper' as t_hyper,
        :'current_mode' = 'compressed' as t_compressed
        \gset

\if :t_compressed
    ALTER TABLE :table_name SET (timescaledb.compress,timescaledb.compress_segmentby = 'device_id, rssi',timescaledb.compress_orderby = 'battery_status');
    select compress_chunk(show_chunks(:'table_name'));
\endif
