truncate table `hmh-carenostics-dev.ckd_table.pat_egfr_ckd`;
insert into `hmh-carenostics-dev.ckd_table.pat_egfr_ckd`
(entity_id, ckd_egfr, number_of_egfrs_post_last_normal)
select entity_id, false, 0
from `hmh-carenostics-dev.ckd_table.cohort`;

-- UPDATE 1
truncate table `hmh-carenostics-dev.ckd_table.CTE`;

insert into  `hmh-carenostics-dev.ckd_table.CTE`
select
    distinct entity_id,
    first_value(event_dttm) over win first_date,
	  first_value(clean_value) over win clean_value
  from
    `hmh-carenostics-dev.ckd_table.egfr_analysis` 
  where
    not is_abnormal -- nulls ignored
    window win as (partition by entity_id
                   order by event_dttm desc)
;


update `hmh-carenostics-dev.ckd_table.pat_egfr_ckd` pe
set
  ckd_last_normal_egfr_date = cte.first_date
from
  `hmh-carenostics-dev.ckd_table.CTE` cte
where
  pe.entity_id = cte.entity_id;


--UPDATE 2
 
truncate table `hmh-carenostics-dev.ckd_table.CTE2`;

insert into  `hmh-carenostics-dev.ckd_table.CTE2`
select
    distinct entity_id,
       first_value(event_dttm) over win first_date,
	     first_value(clean_value) over win clean_value
  from
    `hmh-carenostics-dev.ckd_table.egfr_analysis` 
    window win as (partition by entity_id
                   order by event_dttm desc);


update `hmh-carenostics-dev.ckd_table.pat_egfr_ckd` pe2
set  ckd_last_normal_egfr_date = cte2.first_date,
     ckd_last_egfr_value = cte2.clean_value
from
  `hmh-carenostics-dev.ckd_table.CTE2` cte2
where
  pe2.entity_id = cte2.entity_id;

-- UPDATE 3

truncate table `hmh-carenostics-dev.ckd_table.CTE3`;

insert into  `hmh-carenostics-dev.ckd_table.CTE3`
select
    distinct entity_id,
          -- with ascending event_dttm, the first_value is the first abnormal egfr
         first_value(event_dttm) over win first_date,
	 first_value(clean_value) over win first_clean_value,
         last_value(event_dttm) over win last_date,
	 last_value(clean_value) over win last_clean_value,
	 count(entity_id) over win entity_count  --integer
  from
     `hmh-carenostics-dev.ckd_table.egfr_analysis` egfr
  where
    event_dttm > (select coalesce(ckd_last_normal_egfr_date, timestamp '1900-01-01 00:00:00') 
    from  `hmh-carenostics-dev.ckd_table.pat_egfr_ckd` pe3
  where pe3.entity_id = egfr.entity_id) and
    is_abnormal
    window win as (partition by entity_id
                   order by event_dttm asc
		   rows between unbounded preceding and unbounded following
                  );

update  `hmh-carenostics-dev.ckd_table.pat_egfr_ckd` pe3
set
  ckd_first_abn_egfr_date = cte3.first_date,
  ckd_first_abn_egfr_value = cte3.first_clean_value,
  ckd_last_abn_egfr_date = cte3.last_date,
  ckd_last_abn_egfr_value = cte3.last_clean_value,
  number_of_egfrs_post_last_normal = cte3.entity_count, 
  ckd_egfr = case
    when cte3.entity_count > 1 
    and EXTRACT(DAY FROM Last_date - first_date)  >= 90 then true
		else false
	     end	
from
   `hmh-carenostics-dev.ckd_table.CTE3` cte3
where
  pe3.entity_id = cte3.entity_id;




-- UPDATE 4

truncate table `hmh-carenostics-dev.ckd_table.CTE4`;

insert into  `hmh-carenostics-dev.ckd_table.CTE4`
select
    distinct entity_id,
          -- with ascending event_dttm, the first_value is the first abnormal egfr
         first_value(event_dttm) over win first_date
  from
     `hmh-carenostics-dev.ckd_table.egfr_analysis` egfr
     inner join `hmh-carenostics-dev.ckd_table.pat_egfr_ckd` using(entity_id)
  where
    DATE_DIFF(event_dttm, ckd_first_abn_egfr_date, DAY) >= 90
    window win as (partition by entity_id
                   order by event_dttm asc);

update `hmh-carenostics-dev.ckd_table.pat_egfr_ckd` pe4
set
  ckd_egfr_diagnosis_date = first_date
from
  `hmh-carenostics-dev.ckd_table.CTE4` cte4
where
  pe4.entity_id = cte4.entity_id;
