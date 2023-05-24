truncate table `hmh-carenostics-dev.ckd_table.pat_dx_ckd`;
insert into `hmh-carenostics-dev.ckd_table.pat_dx_ckd`(entity_id)
select entity_id
from 
  `hmh-carenostics-dev.ckd_table.cohort`;


truncate table `hmh-carenostics-dev.ckd_table.DCTE`;
insert into  `hmh-carenostics-dev.ckd_table.DCTE`
  select
    distinct entity_id,
      first_value(event_dttm) over win first_date,
	    first_value(n18) over win first_string_value,
	    first_value(cast(stage as numeric)) over win first_numeric_value
  from
     `hmh-carenostics-dev.ckd_table.ckd_dx_codes`
     
  where
    is_abnormal = 1
  window win as (partition by entity_id
                   order by event_dttm asc, stage desc
		   rows between unbounded preceding and unbounded following);


update
   `hmh-carenostics-dev.ckd_table.pat_dx_ckd` pat_dx_ckd
set
  ckd_first_dx_3_plus_date = first_date,
  ckd_first_dx_3_plus_code = first_string_value,
  ckd_first_dx_3_plus_stage = first_numeric_value,
  ckd_dx = 1
from
  `hmh-carenostics-dev.ckd_table.DCTE` dcte
where
  pat_dx_ckd.entity_id = dcte.entity_id;
 
-- UPDATE 2


truncate table `hmh-carenostics-dev.ckd_table.DCTE2`;
insert into  `hmh-carenostics-dev.ckd_table.DCTE2`
  select
    distinct entity_id,
             first_value(event_dttm) over win first_date
  from
    `hmh-carenostics-dev.ckd_table.ckd_dx_codes` 
  window win as (partition by entity_id
                 order by event_dttm desc
		 ); 
update
  `hmh-carenostics-dev.ckd_table.pat_dx_ckd` pat_dx_ckd
set
  last_dx_date = first_date
from `hmh-carenostics-dev.ckd_table.DCTE2` dcte2
where
  pat_dx_ckd.entity_id = dcte2.entity_id;
 
 
-- Update 3


truncate table `hmh-carenostics-dev.ckd_table.DCTE3`;
insert into  `hmh-carenostics-dev.ckd_table.DCTE3`
  select
    distinct entity_id,
	     first_value(cast(stage as numeric))  over win first_stage
  from
    `hmh-carenostics-dev.ckd_table.ckd_dx_codes` 
  where
    is_abnormal = 1
  window win as (partition by entity_id
                 order by stage desc
		 );

update
  `hmh-carenostics-dev.ckd_table.pat_dx_ckd` pat_dx_ckd
set
  last_dx_stage = first_stage
from `hmh-carenostics-dev.ckd_table.DCTE3` dcte3
where
  pat_dx_ckd.entity_id = dcte3.entity_id; -- add date
 
