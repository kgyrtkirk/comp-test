
setup {
	call load('normal');
	call load('hyper');
	call load('compressed');
}

session "s0"
setup {
	call use('normal');
}
step "s0_append" { call s_append(); }



session "s1"
step "b" {
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
