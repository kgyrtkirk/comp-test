
\if :{?last_mode}
    drop table if exists diff;
    create table diff as
    with
        c as (select count(1) over (partition by time,c),* from :current_mode.:table_name c),
        l as (select count(1) over (partition by time,c),* from :last_mode.:table_name c)
    (
            select * from c
        except
            select * from l
    )
    union all
    (
            select * from l
        except
            select * from c
    );

    select count(1) > 0 as diff_count from diff \gset

    \if :diff_count
        \pset pager off
        select * from diff d order by d limit 4;
    DO $$ BEGIN RAISE EXCEPTION 'differences found: %',(select count(1) from diff);END $$;
    \else
    \endif

\endif