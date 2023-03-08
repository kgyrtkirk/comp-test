select :step+1 as step \gset

-- https://stackoverflow.com/questions/57910070/convert-hypertable-to-regular-postgres-table
CREATE TABLE normal_table (LIKE :table_name INCLUDING ALL); -- duplicate table structure
INSERT INTO normal_table (SELECT * FROM :table_name); -- copy all data
DROP TABLE :table_name; -- drops hypertable
ALTER TABLE normal_table RENAME TO :table_name; -- conditions is now a regular postgres table again
