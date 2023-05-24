/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to get summary information after the sql have been run.
                    
Author:             Michael Greenberg
***************************************************************************************************/ 


drop table if exists summary ;

create table summary (
  label text primary key,
  count integer,
  percent real default(0)
);


insert into summary(label, count) values
  ('patients', (select count(*) from pat_all_flt_ckd)),
  ('ckd_uacr', (select count(*) from pat_all_flt_ckd where ckd_uacr)),
  ('ckd_egfr', (select count(*) from pat_all_flt_ckd where ckd_egfr)),
  ('ckd_dx', (select count(*) from pat_all_flt_ckd where ckd_dx)),
  ('ckd_label', (select count(*) from pat_all_flt_ckd where ckd_label)),
  ('dialysis', (select count(*) from pat_all_flt_ckd where dialysis_dx)),
  ('kidney_transplant_dx', (select count(*) from pat_all_flt_ckd where kidney_transplant_dx)),
  ('cohort_a1', (select count(*) from pat_all_flt_ckd where cohort_a1)),
  ('cohort_a2', (select count(*) from pat_all_flt_ckd where cohort_a2)),
  ('cohort_a3', (select count(*) from pat_all_flt_ckd where cohort_a3)) ;

update summary
set percent = count*100.0/(select count from summary where label ='patients') ;


select label "Label", lpad(to_char(count, 'FM999,999,999'), 11) "Total", round(cast(percent as numeric), 1) "%"
from summary ;
