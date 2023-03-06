

drop view if exists hyper_columns;
create view hyper_columns as 
    select  i.table_schema,
            i.table_name,
            i.column_name,
            ti.dimension_number,
            segmentby_column_index,
            orderby_column_index,
            case
                when dimension_number is not null then 'dimension'
                when segmentby_column_index is not null then 'segmentby'
                when orderby_column_index is not null then 'orderby'
                else 'normal'
            end as column_usage
    from information_schema.columns i
        -- where table_schema = :'current_mode' and table_name=:'table_name'
        left outer join timescaledb_information.dimensions ti on (i.table_name = ti.hypertable_name and i.table_schema = ti.hypertable_schema and i.column_name = ti. column_name)
        left outer join timescaledb_information.compression_settings cs on (i.table_name = cs.hypertable_name and i.table_schema = cs.hypertable_schema and i.column_name = cs.attname)
;
        -- and column_name not in (select column_name from timescaledb_information.dimensions where hypertable_schema = :'current_mode' and hypertable_name=:'table_name')
        -- order by column_name




select :step+1 as step \gset

select  :'current_mode' = 'compressed'
    AND is_hypertable(:'current_mode',:'table_name')
    AND NOT is_compressed(:'current_mode',:'table_name') as proceed \gset

\if :proceed

    \set p_segmentby    .17
    \set p_orderby    .13

    select setseed(1.0/(:step+1));
    with g as (
        select column_name from information_schema.columns
            where table_schema = :'current_mode' and table_name=:'table_name'
            and column_name not in (select column_name from timescaledb_information.dimensions where hypertable_schema = :'current_mode' and hypertable_name=:'table_name')
            order by column_name
    ),
    h as (select random() v,column_name from g)
    select (select coalesce(string_agg(column_name,','),'') from h where v<:p_segmentby) as segmentby, (select coalesce(string_agg(column_name,','),'') from h where v between :p_segmentby and :p_segmentby + :p_orderby) as orderby \gset

    select :'segmentby',:'orderby';
    
    ALTER TABLE :table_name SET (timescaledb.compress,timescaledb.compress_segmentby = 'device_id, rssi',timescaledb.compress_orderby = 'battery_status');
    select compress_chunk(show_chunks(:'table_name'));
\endif
