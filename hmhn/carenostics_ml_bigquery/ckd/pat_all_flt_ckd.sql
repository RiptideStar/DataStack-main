declare dont_use_uacr boolean default $PAT_ALL_FLT_NO_USE_UACR;
declare DEBUG boolean default $DEBUG ;
declare until datetime default(if("$UNTIL_DATE"="", current_datetime, parse_datetime("%F", "$UNTIL_DATE"))) ;
set @@dataset_id = '$DATASET' ;

create or replace 
function `$DATASET`.eligibleForCohort(birth_date datetime, living boolean, dialysis_dx boolean, kidney_transplant_dx boolean) 
returns boolean
as 
  (living
  and date_diff(current_date, birth_date, year) between 18 and 85 
  and not dialysis_dx
  and not kidney_transplant_dx
  )
;

create 
or replace table pat_all_flt_ckd(
  -- first group of data is just copied from existing tables
  entity_id int, 
  birth_date datetime, 
  death_date datetime, 
  -- many are dead w/o a death_date.  So, do not use this for an 'is alive' string
  living boolean not null, 
  ckd_egfr boolean default(false) not null, 
  ckd_last_normal_egfr_date datetime, -- unused
  ckd_first_abn_egfr_date datetime, -- unused
  ckd_first_abn_egfr_value float64,  -- unused
  ckd_last_egfr_test_date datetime, -- unused
  ckd_last_egfr_value float64, -- unused
  ckd_last_abn_egfr_date datetime, -- unused
  ckd_egfr_diagnosis_date datetime, 
  number_of_egfrs_post_last_normal int, 
  ckd_uacr boolean default(false) not null, 
  ckd_last_normal_uacr_date datetime, -- unused
  ckd_first_abn_uacr_date datetime, 
  ckd_first_abn_uacr_value float64, -- unused
  ckd_last_uacr_test_date datetime, -- unused
  ckd_last_uacr_value float64, -- unused
  ckd_last_abn_uacr_date datetime, -- unused
  number_of_uacrs_post_last_normal int, 
  ckd_dx boolean default(false) not null, 
  ckd_first_dx_3_plus_date datetime, 
  ckd_first_dx_3_plus_code string, -- unused
  ckd_first_dx_3_plus_stage float64, -- unused
  last_dx_date datetime, -- unused
  last_dx_stage float64, -- unused
  -- computed data
  dialysis_dx boolean default(false) not null, 
  -- true if directly found via ICD codes
  kidney_transplant_dx boolean default(false) not null, 
  -- true if directly found via ICD codes
  ckd_label boolean default(false) not null, 
  ckd_label_date datetime, 
  cohort_a1 boolean default(false) not null, 
  cohort_a2 boolean default(false) not null, 
  cohort_a3 boolean default(false) not null
);



insert into pat_all_flt_ckd(
  entity_id, birth_date, death_date, 
  living, 

  ckd_egfr, ckd_last_normal_egfr_date, 
  ckd_first_abn_egfr_date, ckd_first_abn_egfr_value, 
  ckd_last_egfr_test_date, ckd_last_egfr_value, 
  ckd_last_abn_egfr_date, ckd_egfr_diagnosis_date, 
  number_of_egfrs_post_last_normal, 

  ckd_uacr, ckd_last_normal_uacr_date, 
  ckd_first_abn_uacr_date, ckd_first_abn_uacr_value, 
  ckd_last_uacr_test_date, ckd_last_uacr_value, 
  ckd_last_abn_uacr_date, number_of_uacrs_post_last_normal, 

  ckd_dx, ckd_first_dx_3_plus_date, 
  ckd_first_dx_3_plus_code, ckd_first_dx_3_plus_stage, 
  last_dx_date, last_dx_stage
) 
select 
  de.entity_id, 
  de.birth_date, 
  de.death_date, 
  case when de.death_date is not null then false when de.living_status = 2 then false else true end, 
  eg.ckd_egfr, 
  eg.ckd_last_normal_egfr_date, 
  eg.ckd_first_abn_egfr_date, 
  eg.ckd_first_abn_egfr_value, 
  eg.ckd_last_egfr_date, 
  eg.ckd_last_egfr_value, 
  eg.ckd_last_abn_egfr_date, 
  eg.ckd_egfr_diagnosis_date, 
  eg.number_of_egfrs_post_last_normal, 
  if(dont_use_uacr, false, ua.ckd_uacr), 
  if(dont_use_uacr, null, ua.ckd_last_normal_uacr_date),
  if(dont_use_uacr, null, ua.ckd_first_abn_uacr_date),
  if(dont_use_uacr, null, ua.ckd_first_abn_uacr_value),
  if(dont_use_uacr, null, ua.ckd_last_uacr_date),
  if(dont_use_uacr, null, ua.ckd_last_uacr_value),
  if(dont_use_uacr, null, ua.ckd_last_abn_uacr_date),
  if(dont_use_uacr, null, ua.number_of_uacrs_post_last_normal),
  dx.ckd_dx, 
  dx.ckd_first_dx_3_plus_date, 
  dx.ckd_first_dx_3_plus_code, 
  dx.ckd_first_dx_3_plus_stage, 
  dx.last_dx_date, 
  dx.last_dx_stage 
from 
  $ML.demographics as de 
  join pat_egfr_ckd as eg using (entity_id) 
  join pat_uacr_ckd as ua using (entity_id) 
  join pat_dx_ckd as dx using (entity_id);


update 
  pat_all_flt_ckd 
set 
  ckd_label = true, 
  ckd_label_date = least(
    coalesce(ckd_first_dx_3_plus_date, datetime '2100-01-01'), 
    coalesce(ckd_egfr_diagnosis_date, datetime '2100-01-01'),
    coalesce(ckd_first_abn_uacr_date, datetime '2100-01-01')
  )
where 
  ckd_egfr 
  or ckd_dx
  or ckd_uacr ;


update 
  pat_all_flt_ckd 
set 
  dialysis_dx = true 
where 
  entity_id in (
    select 
      distinct(entity_id) 
    from 
      $ML.conditions 
    where 
      event_code IN (
        'I95.3', 'R88.0', 'T85.611A', 'T85.621A', 
        'T85.631A', 'T85.691A', 'T85.71XA', 
        'Y84.1', 'Z49.0', 'Z49.31', 'Z49.32', 
        'Z91.15', 'Z99.2'
      )
    and event_dttm <= until
  );

update 
  pat_all_flt_ckd 
set 
  kidney_transplant_dx = true 
where 
  entity_id in (
    select 
      distinct(entity_id) 
    from 
      $ML.conditions 
    where 
      event_code IN (
        'T86.10', 'T86.11', 'T86.12', 'T86.13', 
        'T86.19', 'Z48.22', 'Z94.0'
      )
      and event_dttm <= until
  );


-- Living patients with age [18, 85]  has at least ONE abnormal lab value (eGFR or UACR) but not a second confirmatory lab test. Patient has no diagnosis code for CKD.
-- no kidney transpland or dialysis

update 
  pat_all_flt_ckd 
set 
  cohort_a1 = true 
where 
 `$DATASET`.eligibleForCohort(birth_date, living, dialysis_dx, kidney_transplant_dx)
  and not ckd_label 
  and (
    number_of_uacrs_post_last_normal > 0 or
    number_of_egfrs_post_last_normal > 0
  ) 
  ;



-- Living patients with age [18, 85] with inferred CKD with not CKD diagnosis with no kidney/dialysis

update 
  pat_all_flt_ckd 
set 
  cohort_a2 = true 
where 
 `$DATASET`.eligibleForCohort(birth_date, living, dialysis_dx, kidney_transplant_dx)
  and ckd_label = true 
  and not ckd_dx ;



-- Living patients with age [18, 85] with no kidney/dialysis
-- with CKD diagnosis and no treatment

update 
  pat_all_flt_ckd 
set 
  cohort_a3 = true 
where 
 `$DATASET`.eligibleForCohort(birth_date, living, dialysis_dx, kidney_transplant_dx)
  and ckd_dx 
  and not exists (
    select 
      1 
    from 
      $ML.medications 
    where 
      medications.entity_id = pat_all_flt_ckd.entity_id 
      and pharm_subclass in (2770, 3750, 3610, 3615) 
      and datetime_add(effective_end_time, interval 30 day) >= until
      and start_time <= until
  ) ;


select utils.formatInt(count(*)) `pat_all_flt_ckd size` from pat_all_flt_ckd;


if DEBUG
then
  select * from pat_all_flt_ckd limit 10;
end if ;
