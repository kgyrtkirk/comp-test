
select :step+1 as step \gset

select  :'current_mode' = 'compressed'
    AND is_hypertable(:'current_mode',:'table_name')
    AND NOT is_compressed(:'current_mode',:'table_name') as proceed \gset

\if :proceed

    \set p_segmentby    .17
    \set p_orderby    .13

    select setseed(1.0/(:step+1));
    with g as (
        select column_name from hyper_columns
            where table_schema = :'current_mode' and table_name=:'table_name' and column_usage ='normal'
        order by column_name
    ),
    h as (select random() v,column_name from g)
    select (select coalesce(string_agg(column_name,','),'') from h where v<:p_segmentby) as segmentby, (select coalesce(string_agg(column_name,','),'') from h where v between :p_segmentby and :p_segmentby + :p_orderby) as orderby \gset

    select :'segmentby',:'orderby';
    
    ALTER TABLE :table_name SET (timescaledb.compress,timescaledb.compress_segmentby = :'segmentby',timescaledb.compress_orderby = :'orderby');
    select compress_chunk(show_chunks(:'table_name'));
\endif
