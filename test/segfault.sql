DROP TABLE IF EXISTS readings;
CREATE TABLE readings(
    time  TIMESTAMP WITH TIME ZONE NOT NULL,
    battery_temperature  DOUBLE PRECISION,
    battery_status  TEXT
);

insert into readings (time) values ('2022-11-11 11:11:11');
insert into readings (time) values ('2022-11-11 11:11:11');
insert into readings (time) values ('2022-11-11 11:11:11');
insert into readings (time) values ('2022-11-11 11:11:11');
insert into readings (time) values ('2022-11-11 11:11:11');
-- insert into readings  values ('2022-11-11 11:11:11',0.1,111);

SELECT create_hypertable(:'table_name', 'time', chunk_time_interval => interval '12 hour', migrate_data=>true);

ALTER TABLE :table_name SET (timescaledb.compress,timescaledb.compress_segmentby = 'battery_temperature');
select compress_chunk(show_chunks(:'table_name'));

alter table :current_mode.readings drop column battery_status;
-- alter table :current_mode.readings add column bx integer ;
-- alter table :current_mode.readings add column bx integer ;
-- insert into readings  values ('2022-11-11 11:11:11',1.0,111);
insert into readings  values ('2022-11-11 11:11:11',0.2);
select * from readings;
explain  verbose
select c from  :current_mode.readings c;
select c from  :current_mode.readings c;