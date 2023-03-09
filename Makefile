EXTENSION = comptest
DATA = comptest--1.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

install: $(DATA)
$(DATA):	runner/test_extensions.sql
	cat $^ > $@
