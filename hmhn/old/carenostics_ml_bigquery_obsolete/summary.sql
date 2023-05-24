--------------------------------------------------------------------------------------------
-- Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
-- via any medium is strictly prohibited 
--
-- Proprietary and Confidential
-- 
-- Description:        This SQL is used to get summary information after the sql have been run.
--                    
-- Author:             Michael Greenberg
-----------------------------------------------------------------------------------------------


\timing off
-- set this to 'on' if you just want to see the summary and not recreate the results
\skip off
drop table if exists summary ;

create table summary (
  sort_order int,
  label string,
  count int,
  percent float64
);

\time_as 'create summary'
insert into summary(sort_order, label, count) values
  (0, 'patients', (select count(*) from pat_all_flt_ckd)),
  (1, 'ckd_uacr', (select count(*) from pat_all_flt_ckd where ckd_uacr)),
  (2, 'ckd_egfr', (select count(*) from pat_all_flt_ckd where ckd_egfr)),
  (3, 'ckd_dx', (select count(*) from pat_all_flt_ckd where ckd_dx)),
  (4, 'ckd_label', (select count(*) from pat_all_flt_ckd where ckd_label)),
  (5, 'dialysis', (select count(*) from pat_all_flt_ckd where dialysis_dx)),
  (6, 'kidney_transplant_dx', (select count(*) from pat_all_flt_ckd where kidney_transplant_dx)),
  (7, 'cohort_a1', (select count(*) from pat_all_flt_ckd where cohort_a1)),
  (8, 'cohort_a2', (select count(*) from pat_all_flt_ckd where cohort_a2)),
  (9, 'cohort_a3', (select count(*) from pat_all_flt_ckd where cohort_a3)) ;


update summary
set percent = count*100.0/(select count from summary where label ='patients') 
where true ;

\headers Label;Count;%
\floatfmt .1f
\intfmt ,
select label, count, percent
from summary 
order by sort_order;

