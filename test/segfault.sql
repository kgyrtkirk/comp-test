DROP TABLE IF EXISTS readings;
CREATE TABLE readings(
    time  TIMESTAMP WITH TIME ZONE NOT NULL,
    battery_status  TEXT,   
    battery_temperature  DOUBLE PRECISION
);

insert into readings (time) values ('2022-11-11 11:11:11');

SELECT create_hypertable(:'table_name', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true);

ALTER TABLE :table_name SET (timescaledb.compress,timescaledb.compress_segmentby = 'battery_temperature');
select compress_chunk(show_chunks(:'table_name'));

alter table :current_mode.readings drop column battery_status;
select * from readings;
explain select count(1) over (partition by time,c),* from  :current_mode.readings c;
select count(1) over (partition by time,c),* from  :current_mode.readings c;
