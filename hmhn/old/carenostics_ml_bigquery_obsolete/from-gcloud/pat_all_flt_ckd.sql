truncate table `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`;

insert into  `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
  select
    de.entity_id,
    cast (de.birth_date as timestamp),
    cast (de.death_date as timestamp),
    eg.ckd_egfr,
    ckd_last_egfr_date as ckd_last_egfr_test_date,
    eg.ckd_last_egfr_value,
    eg.ckd_last_egfr_num_value,
    eg.ckd_last_normal_egfr_date,
    eg.ckd_last_abn_egfr_date, 
    eg.ckd_first_abn_egfr_date,
    eg.ckd_first_abn_egfr_value,
    eg.ckd_first_abn_egfr_num_value,
    eg.number_of_egfrs_post_last_normal,
    ua.ckd_uacr,
    ua.ckd_last_uacr_test_date,
    ua.ckd_last_uacr_value,
    cast(ua.ckd_last_uacr_num_value as numeric),
    ua.ckd_last_normal_uacr_date,
    ua.ckd_last_abn_uacr_date, 
    ua.ckd_first_abn_uacr_date,
    ua.ckd_first_abn_uacr_value,
    ua.ckd_first_abn_uacr_num_value,
    ua.number_of_uacrs_post_last_normal,
    dx.ckd_first_dx_3_plus_date,
    dx.ckd_dx,
    dx.ckd_first_dx_3_plus_code,
    dx.ckd_first_dx_3_plus_stage,
    dx.last_dx_date, 
    dx.last_dx_stage,
    null as ckd_label,
    null as ckd_label_date,
    null as dialysis_dx,
    null as kidney_transplant_dx,
    null as cohort_a1,
    null as cohort_a2,    
    null as cohort_a3

from  `hmh-carenostics-dev.ckd_table.demographics` as de
left join  `hmh-carenostics-dev.ckd_table.pat_egfr_ckd` as eg using (entity_id)    
left join  `hmh-carenostics-dev.ckd_table.pat_dx_ckd` as dx using (entity_id)
left join  `hmh-carenostics-dev.ckd_table.pat_uacr_ckd` as ua using (entity_id);


update `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set ckd_egfr = 0
where entity_id in (select distinct(entity_id) from `hmh-carenostics-dev.ckd_table.egfr_analysis` where is_valid != 0) 
and 
ckd_egfr is null;

update `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set ckd_uacr = 0
where entity_id in (select distinct(entity_id) from `hmh-carenostics-dev.ckd_table.uacr_analysis` where is_valid != 0) 
and 
ckd_uacr is null;



--create label ckd_label

update `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set ckd_label = 0
where (ckd_egfr = 0 or ckd_uacr = 0) and (ckd_dx = 0 or ckd_dx is null);

update `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set ckd_label = 1
where ckd_egfr = 1 or ckd_dx = 1 or ckd_uacr = 1;


--create label ckd_label_date

update  `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set ckd_label_date = least(ckd_first_dx_3_plus_date, ckd_first_abn_egfr_date, ckd_first_abn_uacr_date)
where ckd_label_date is null; 


update `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set dialysis_dx = 1
where entity_id 
  in (select distinct(entity_id) 
        from `hmh-carenostics-dev.ckd_table.conditions` 
        where event_code 
        IN ('I95.3','R88.0','T85.611A','T85.621A','T85.631A','T85.691A','T85.71XA','Y84.1','Z49.0','Z49.31','Z49.32','Z91.15','Z99.2')
    );

-- Update the patient flat table for kidney transplant
update `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set kidney_transplant_dx = 1
where entity_id 
  in (select distinct(entity_id) 
        from `hmh-carenostics-dev.ckd_table.conditions` 
        where event_code 
          IN ('T86.10','T86.11','T86.12','T86.13','T86.19','Z48.22','Z94.0')
  );

-- Update the patient flat table for cohort A1
update `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set cohort_a1 = 1
where 
  ckd_label=0 
  and (greatest(number_of_uacrs_post_last_normal,number_of_egfrs_post_last_normal)>0)
  and  greatest((extract(day from ckd_last_abn_egfr_date)- extract(day from ckd_first_abn_egfr_date)),
            (extract(day from ckd_last_abn_uacr_date)- extract(day from ckd_first_abn_egfr_date))) <= 90
  and (extract(year from current_date) - extract(year from birth_date)) > 17 
  and (extract(day from ckd_last_abn_egfr_date) - extract(year from birth_date)) <86
  and ckd_dx is null
  and death_date is null
  and dialysis_dx is null
  and kidney_transplant_dx is null;

-- Update the patient flat table for cohort A2
update `hmh-carenostics-dev.ckd_table.pat_all_flt_ckd`
set cohort_a2 = 1
where 
  ckd_label=1 
  and (ckd_egfr = 1 or ckd_uacr = 1)  
  and (extract(year from current_date) - extract(year from birth_date)) > 17 
  and (extract(day from ckd_last_abn_egfr_date) - extract(year from birth_date)) <86
  and ckd_dx is null
  and death_date is null
  and dialysis_dx is null
  and kidney_transplant_dx is null;
