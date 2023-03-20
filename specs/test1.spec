
setup {
	m4_include(test/framework.pgsql)

	call load('normal','0');
	call load('hyper','0');
	call load('compressed','0');
}

m4_define(call_step,step s$1_$2	{ call s_$2(); })
m4_define(`new_session',
session s$1_$2
setup {
	call switch_to('$2','0');
}
call_step($1,append)
call_step($1,hyper)
call_step($1,unhyper)
call_step($1,delete)
call_step($1,compress)
call_step($1,uncompress)
call_step($1,column_add_default)
call_step($1,column_add_nullable)

step s$1_nop {}
step s$1_cmp {	call compare('normal_0','compressed_0');}

)

new_session(0,normal)
new_session(1,normal)
new_session(2,compressed)
new_session(3,compressed)


m4_define(seq,
	$1_hyper
	$1_append (*)
	$1_compress
	$2_append (*)
	$1_column_add_default (*)
	$1_nop
	$2_nop
	$1_append (*)
	$2_uncompress (*)
	$1_nop
	$2_nop
	$1_uncompress
	$1_column_add_nullable (*)
	$2_uncompress
	$1_append (*)
	$2_compress (*)
	$1_nop
	$2_nop
	$1_uncompress
	$1_column_add_default
	$1_nop
	$2_nop
	$1_compress (*)
	$1_nop
	$2_nop
	$2_append (*)
	$1_uncompress (*)
	$1_nop
	$2_nop
	$1_uncompress (*)
	$2_append (*)
	$2_compress (*)
	$1_column_add_default (*)
	$2_append (*)
	$1_nop
	$2_nop
)

permutation
	seq(s0,s1)
	seq(s2,s3)
	s0_cmp
