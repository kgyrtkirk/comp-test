
setup {
	m4_include(test/framework.pgsql)

	call load('normal','0');
	call load('hyper','0');  
	call load('compressed','0');
}

m4_define(call_step,step $1_$2	{ call s_$2(); })
m4_define(`new_session',
session $1_$2
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
call_step($1,column_drop)
call_step($1,blank)
step $1_begin { begin; }
step $1_commit { commit; }
step $1_appendx { insert into compressed_0.main_table select * from compressed_0.main_table where device_id = 'demo000148' and time='2016-11-29 11:34:30.000011+00'; }
step $1_append2 { select get_var2('step_idx');call s_append('1'); }


step $1_nop {}
step $1_cmp {	
	call create_diff('normal_0','compressed_0');
	call compare('normal_0','compressed_0');}

)

new_session(n0,normal)
new_session(n1,normal)
new_session(c0,compressed)
new_session(c1,compressed)


m4_define(seq,
	$1_hyper
	$1_append
	$2_append
	$1_append2
	$2_append
	$2_blank
	$1_append2
	$1_nop
	$2_nop
	$2_compress
	$1_nop
	$2_nop
	$1_append2
	$1_nop
	$2_nop
)

permutation
	seq(n0,n1)
	seq(c0,c1)
	n0_cmp
