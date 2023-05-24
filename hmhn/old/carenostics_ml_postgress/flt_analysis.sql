/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to get summary information after the sql have been run.
                    
Author:             Michael Greenberg
***************************************************************************************************/ 


--------------pat_all_flt_ckd table--------------
drop 
	table if exists pat_all_flt_ckd;
-- todo: only store clean values and is abnormal
create table pat_all_flt_ckd(
  	entity_id bigint primary key,
	birth_date timestamp(0) null, 
  	death_date timestamp(0) null, -- many are dead w/o a death_date.  So, do not use this for an 'is alive' test
  	living boolean not null, 
  	ckd_egfr boolean not null,
  	ckd_last_egfr_test_date timestamp(0) null,
  	ckd_last_egfr_value real null,
  	ckd_last_normal_egfr_date timestamp(0) null,
  	ckd_last_abn_egfr_date timestamp(0) null, 
  	ckd_first_abn_egfr_date timestamp(0) null,
  	ckd_first_abn_egfr_value real null,
	ckd_egfr_diagnosis_date timestamp(0) null,
  	number_of_egfrs_post_last_normal bigint null,
  	ckd_uacr boolean not null,
  	ckd_last_uacr_test_date timestamp(0) null,
  	ckd_last_uacr_value text null,
  	ckd_last_uacr_num_value double precision null,
  	ckd_last_normal_uacr_date timestamp(0) null,
  	ckd_last_abn_uacr_date timestamp(0) null, 
  	ckd_first_abn_uacr_date timestamp(0) null,
  	ckd_first_abn_uacr_value text null,
  	ckd_first_abn_uacr_num_value bigint null,
  	number_of_uacrs_post_last_normal bigint null,
  	ckd_first_dx_3_plus_date timestamp(0) null,
  	ckd_dx boolean not null,
  	ckd_first_dx_3_plus_code text null,
  	ckd_first_dx_3_plus_stage double precision null,
  	last_dx_date timestamp(0) null, 
  	last_dx_stage double precision null,

  	ckd_label boolean not null default(false),   --  true if either directly diagnosed with CKD via ICD codes, or inferred via EGFR or via UACR
	ckd_label_date timestamp(0) null, -- date of the earliest diagnosis
  	dialysis_dx boolean not null default(false), -- true if directly found via ICD codes
  	kidney_transplant_dx boolean not null default(false), -- true if directly found via ICD codes
	cohort_a1 boolean not null default(false),
	cohort_a2 boolean not null default(false),
	cohort_a3 boolean not null default(false)
);

--------------pat_all_flt_ckd table----------------

create index on pat_all_flt_ckd(ckd_label) ;
create index on pat_all_flt_ckd(cohort_a1) ;
create index on pat_all_flt_ckd(cohort_a2) ;
create index on pat_all_flt_ckd(cohort_a3) ;


\timing on

\echo 'insert into pat_all_flt_ckd '
insert into pat_all_flt_ckd(entity_id,birth_date,death_date,living,

                            ckd_egfr,ckd_last_egfr_test_date,ckd_last_egfr_value,
                            ckd_last_normal_egfr_date,ckd_last_abn_egfr_date,ckd_first_abn_egfr_date,
			    ckd_first_abn_egfr_value,ckd_egfr_diagnosis_date,
                            number_of_egfrs_post_last_normal,

                            ckd_uacr,ckd_last_uacr_test_date,ckd_last_uacr_value,ckd_last_uacr_num_value,
                            ckd_last_normal_uacr_date,ckd_last_abn_uacr_date,ckd_first_abn_uacr_date,ckd_first_abn_uacr_value,ckd_first_abn_uacr_num_value,
			    number_of_uacrs_post_last_normal,

                            ckd_first_dx_3_plus_date,ckd_dx,ckd_first_dx_3_plus_code,ckd_first_dx_3_plus_stage,last_dx_date,last_dx_stage)

  select
    de.entity_id,
    de.birth_date,
    de.death_date,
    case
      when de.death_date is not null then false
      when de.living_status = 2 then false
      else true
    end,  
    coalesce(eg.ckd_egfr, false), -- in case we make ckd_egfr to bee NULLABLE
    eg.ckd_last_egfr_date,
    eg.ckd_last_egfr_value,
    eg.ckd_last_normal_egfr_date,
    eg.ckd_last_abn_egfr_date, 
    eg.ckd_first_abn_egfr_date,
    eg.ckd_first_abn_egfr_value,
    eg.ckd_egfr_diagnosis_date,
    eg.number_of_egfrs_post_last_normal,
    coalesce(ua.ckd_uacr, false),
    ua.ckd_last_uacr_test_date,
    ua.ckd_last_uacr_value,
    ua.ckd_last_uacr_num_value,
    ua.ckd_last_normal_uacr_date,
    ua.ckd_last_abn_uacr_date, 
    ua.ckd_first_abn_uacr_date,
    ua.ckd_first_abn_uacr_value,
    ua.ckd_first_abn_uacr_num_value,
    ua.number_of_uacrs_post_last_normal,
    dx.ckd_first_dx_3_plus_date,
    coalesce(dx.ckd_dx, 0)::boolean,
    dx.ckd_first_dx_3_plus_code,
    dx.ckd_first_dx_3_plus_stage,
    dx.last_dx_date, 
    dx.last_dx_stage
from demographics as de
  left join pat_egfr_ckd as eg using (entity_id)    
  left join pat_dx_ckd as dx using (entity_id)
  left join pat_uacr_ckd as ua using (entity_id);



--create label ckd_label
\echo 'update pat_all_flt_ckd 4'
update pat_all_flt_ckd
set
  ckd_label = true,
  ckd_label_date = least(ckd_first_dx_3_plus_date, ckd_egfr_diagnosis_date, ckd_first_abn_uacr_date)
where
  ckd_egfr or ckd_dx or ckd_uacr ;


-- Update the patient flat table for dialysis
\echo 'update pat_all_flt_ckd for dialysis_dx column'
update pat_all_flt_ckd
set dialysis_dx = true
where entity_id 
  in (select distinct(entity_id) 
        from conditions 
        where event_code 
        IN ('I95.3','R88.0','T85.611A','T85.621A','T85.631A','T85.691A','T85.71XA','Y84.1','Z49.0','Z49.31','Z49.32','Z91.15','Z99.2')
    );

-- Update the patient flat table for kidney transplant
\echo 'update pat_all_flt_ckd for kidney_transplant_dx column'
update pat_all_flt_ckd
set kidney_transplant_dx = true
where entity_id 
  in (select distinct(entity_id) 
        from conditions 
        where event_code 
          IN ('T86.10','T86.11','T86.12','T86.13','T86.19','Z48.22','Z94.0')
  );


-- Living patients with age [18, 85]  has at least ONE abnormal lab value (eGFR or UACR) but not a second confirmatory lab test. Patient has no diagnosis code for CKD.
-- no kidney transpland or dialysis
\echo 'cohort a1'
update pat_all_flt_ckd
set cohort_a1 = true
where 
  ckd_label=false
  and greatest(number_of_uacrs_post_last_normal,number_of_egfrs_post_last_normal)>0
  and (DATE_PART('year',current_date) - DATE_PART('year', birth_date)) between 18 and 85
  and living
  and dialysis_dx = false
  and kidney_transplant_dx = false;

-- Living patients with age [18, 85] with inferred CKD with not CKD diagnosis witn no kidney/dialysis
\echo 'cohort a2'
update pat_all_flt_ckd
set cohort_a2 = true
where 
  ckd_label = true
  and ckd_dx = false
  and (DATE_PART('year',current_date) - DATE_PART('year', birth_date)) between 18 and 85
  and living
  and dialysis_dx = false
  and kidney_transplant_dx = false;


-- Living patients with age [18, 85] witn no kidney/dialysis
-- with CKD diagnosis and no treatment
\echo 'cohort a3'
update
  pat_all_flt_ckd
set
  cohort_a3 = true
where
  ckd_dx
  and not exists (select 1
                  from medications
	          where
	             medications.entity_id = pat_all_flt_ckd.entity_id and
                     pharm_subclass in (2770,3750,3610,3615) and
		     discon_time is NULL) 
  and (DATE_PART('year',current_date) - DATE_PART('year', birth_date)) between 18 and 85
  and living
  and dialysis_dx = false
  and kidney_transplant_dx = false;
