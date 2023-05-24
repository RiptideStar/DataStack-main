truncate table `hmh-carenostics-dev.ckd_table.pat_uacr_ckd`;
insert into `hmh-carenostics-dev.ckd_table.pat_uacr_ckd`(entity_id)

select entity_id
from `hmh-carenostics-dev.ckd_table.cohort`;


-- UPDATE 1
truncate table `hmh-carenostics-dev.ckd_table.UCTE`;

insert into  `hmh-carenostics-dev.ckd_table.UCTE`
  select
    distinct entity_id,
      first_value(event_dttm) over win first_date,
	    first_value(event_value_string) over win first_string_value,
	    first_value(event_value_numeric) over win first_numeric_value
  from
     `hmh-carenostics-dev.ckd_table.uacr_analysis`
      window win as (partition by entity_id  	     	  
                   order by event_dttm desc, visit_id desc);

update `hmh-carenostics-dev.ckd_table.pat_uacr_ckd` pau
set
	ckd_last_uacr_test_date = first_date,
	ckd_last_uacr_value = first_string_value,
	ckd_last_uacr_num_value = first_numeric_value
from
  `hmh-carenostics-dev.ckd_table.UCTE` UCTE
where
pau.entity_id = UCTE.entity_id;



--UPDATE 2
 
truncate table `hmh-carenostics-dev.ckd_table.UCTE2`;

insert into  `hmh-carenostics-dev.ckd_table.UCTE2`
  select
    distinct entity_id,
      first_value(event_dttm) over win first_date,
	    first_value(event_value_string) over win first_string_value,
	    first_value(event_value_numeric) over win first_numeric_value
  from
     `hmh-carenostics-dev.ckd_table.uacr_analysis`
  where
    is_abnormal = 0
  window win as (partition by entity_id
                   order by event_dttm desc,visit_id desc);
                  

update `hmh-carenostics-dev.ckd_table.pat_uacr_ckd` pau2
set
  ckd_last_normal_uacr_date = first_date
from
  `hmh-carenostics-dev.ckd_table.UCTE2` UCTE2
where
  pau2.entity_id = UCTE2.entity_id;


-- UPDATE 3

truncate table `hmh-carenostics-dev.ckd_table.UCTE3`;

insert into  `hmh-carenostics-dev.ckd_table.UCTE3`
  select
    distinct entity_id,
      first_value(event_dttm) over win first_date,
	    first_value(event_value_string) over win first_string_value,
	    first_value(event_value_numeric) over win first_numeric_value,
      last_value(event_dttm) over win last_date,
	    last_value(event_value_string) over win last_string_value,
	    last_value(event_value_numeric) over win last_numeric_value,
	    count(entity_id) over win count
  from
    `hmh-carenostics-dev.ckd_table.uacr_analysis` ua3
  where
    event_dttm > (select coalesce(ckd_last_normal_uacr_date, timestamp '1900-01-01 00:00:00') 
    from `hmh-carenostics-dev.ckd_table.pat_uacr_ckd` pau3 
    where pau3.entity_id = ua3.entity_id) and
    is_abnormal = 1
    window win as (partition by entity_id
                   order by event_dttm asc,            
    	       	      visit_id desc 
                     rows between unbounded preceding and unbounded following
                   );

update `hmh-carenostics-dev.ckd_table.pat_uacr_ckd` pau3
set
  ckd_first_abn_uacr_date = UCTE3.first_date,
  ckd_first_abn_uacr_value = UCTE3.first_string_value,
  ckd_first_abn_uacr_num_value = cast(UCTE3.first_numeric_value as INTEGER),
  ckd_last_abn_uacr_date = UCTE3.last_date,
  number_of_uacrs_post_last_normal = UCTE3.count,
  ckd_uacr = 
    case 
      when 
        UCTE3.count > 0 and 
        UCTE3.first_numeric_value > 300 
    then 1
    else
      case
        when 
          UCTE3.count > 0 and 
          UCTE3.first_numeric_value > 30 and 
          UCTE3.first_numeric_value <= 300 and 
          --EXTRACT(DAY FROM (UCTE3.last_date - UCTE3.first_date)) >= 90 
          DATE_DIFF(UCTE3.last_date, UCTE3.first_date, DAY) >= 90
        then 1
		    else 0
      end
	 end
from
   `hmh-carenostics-dev.ckd_table.UCTE3`  UCTE3
where
  pau3.entity_id = UCTE3.entity_id;



