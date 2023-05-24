-- Demographics
-- Carenostics/JoEllen
-- revisions as of 3/8/23

  truncate table `hmh-carenostics-dev.ckd_table.demographics`;

  insert into  `hmh-carenostics-dev.ckd_table.demographics`(entity_id, birth_date, death_date, gender, race, ethnicity, city, state, zip, marital_status, living_status)
    
  select 
  distinct
  entity_id,
  birth_date, 
  death_date, 
  sex_c as gender, 
  pr.patient_race_c as race,   
  ethnic_group_c as ethnicity, 
  city, 
  state_c as state, 
  zip,
  marital_status_c as marital_status,  
  cast(pat_living_stat_c as integer) as living_status
 
from `hmh-carenostics-dev.ckd_table.cohort`
join `hmh-carenostics-dev.ckd_table.pat_id_to_entity_id` as pte using(entity_id)
join  `hmh-datalake-prod-c5b4.CLARITY.PATIENT` as pt using(pat_id)
left join `hmh-datalake-prod-c5b4.CLARITY.PATIENT_RACE` as pr 
  on (pt.pat_id = pr.pat_id
  and (pr.line = 1 or pr.line is null))
left join `hmh-datalake-prod-c5b4.CLARITY.PATIENT_4` as p4 on(pt.pat_id = p4.pat_id)  
left join `hmh-carenostics-dev.ckd_view.all_races`  as rc 
             on pr.patient_race_c = rc.race              
left join `hmh-carenostics-dev.ckd_view.all_genders`  as gn 
             on pt.sex_c = gn.gender 
left join `hmh-carenostics-dev.ckd_view.all_ethnicity` as et 
             on pt.ethnic_group_c = et.ethnicity 
left join `hmh-carenostics-dev.ckd_view.all_marital_status` as ma on pt.marital_status_c = ma.marital_status
