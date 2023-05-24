

\if false
\echo 'count v3'
select count(*) from pat_all_flt_ckd where cohort_a3;
update pat_all_flt_ckd set cohort_a3 = false where cohort_a3 = true ;

-- 28,019 in 3:11
\echo 'cohort a3 V2'
-- ckd patients currently taking the relevant type of drug
with patientsWithMeds as (
  select
    distinct entity_id
  from
    pat_all_flt_ckd join medications using(entity_id)
  where 
    ckd_label=true and
    pharm_subclass in (2770,3750,3610,3615) and
    discon_time is NULL 
)
update
  pat_all_flt_ckd
set
  cohort_a3 = true
where
  ckd_label = true and
  (DATE_PART('year',current_date::date) - DATE_PART('year', birth_date::date)) > 17   and
  (DATE_PART('year',ckd_last_abn_egfr_date::date) - DATE_PART('year', birth_date::date))<86 and
  death_date is null and
  dialysis_dx = false and
  kidney_transplant_dx = false and
  not exists (select 1 from patientsWithMeds where patientsWithMeds.entity_id = pat_all_flt_ckd.entity_id) ;

\echo 'count v1'
select count(*) from pat_all_flt_ckd where cohort_a3;
update pat_all_flt_ckd set cohort_a3 = false where cohort_a3 = true ;

-- 28,019 in 4:16
\echo 'cohort a3 v1'
-- 5 min
-- ckd patients currently taking the relevant type of drug
with patientsWithMeds as (
  select
    distinct entity_id
  from
    pat_all_flt_ckd join medications using(entity_id)
  where 
    ckd_label=true and
    pharm_subclass in (2770,3750,3610,3615) and
    discon_time is NULL 
)
update
  pat_all_flt_ckd
set
  cohort_a3 = true
where
  ckd_label = true and
  (DATE_PART('year',current_date::date) - DATE_PART('year', birth_date::date)) > 17   and
  (DATE_PART('year',ckd_last_abn_egfr_date::date) - DATE_PART('year', birth_date::date))<86 and
  death_date is null and
  dialysis_dx = false and
  kidney_transplant_dx = false and
  entity_id not in (select entity_id from patientsWithMeds) ;
\echo 'count v2'
select count(*) from pat_all_flt_ckd where cohort_a3;
\endif



