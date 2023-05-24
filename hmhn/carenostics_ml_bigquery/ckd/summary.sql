set @@dataset_id = '$DATASET' ;

create or replace table summary (
  sort_order int,
  label string,
  count int,
  percent float64
);

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

-- select label as `Labels in $DATASET`, format("%'10d",count) as `Count`, format("%5.1f", percent) as `%`
select label as `Labels in $DATASET`, count as `Count`, utils.formatPct(percent) as `%`
from summary
order by sort_order;
