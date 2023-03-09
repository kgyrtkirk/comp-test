
setup {
	create table t as select now() as t,0 as v;
	create table t2 as select now() as t,0 as v;
}

session "s1"
step "b" {
	--select pg_sleep(.1);
	insert into t2 values (now(),2);
}
session "s3"
step "r0" {}
step "r" {
	select * from t;
	select * from t2;
}

session "s2"
step "a" {
	insert into t values (now(),10);
--	select pg_sleep(1);
	insert into t values (now(),11);
	
}
step "a2" {
	DO $$ BEGIN RAISE NOTICE 'invalid mode: %','current_mode';END $$;
}


permutation
	"b" (*) 
	"a" (*)
	"b" (*)
	"a" (*)
	"r0" ("a","b")
	"r"
