select :step+1 as step \gset

select :'current_mode' != 'normal' AND NOT is_hypertable(:'current_mode',:'table_name') as proceed \gset

\if :proceed
    SELECT create_hypertable(:'table_name', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true);
\endif
