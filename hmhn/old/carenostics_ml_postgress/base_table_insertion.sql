/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to update base tables required for ML analysis. This 
                    includes reference tables, and resources tables (demographics, conditions
                    encounters, labs, medications, vitals, procedures)
                    
Author:             Michael Greenberg
***************************************************************************************************/  

\timing on

--formnat the file
--add cohort 

--------------reference tables--------------

--truncate all_races cascade;
\echo 'insert into all_races'
insert into all_races 
select 
  patient_race_c as race, 
  name as race_description 
from 
  {sourceSchema}.zc_patient_race;

--truncate all_genders cascade; 
\echo 'insert into all_genders'
insert into all_genders 
select 
  rcpt_mem_sex_c as gender, 
  name as gender_description 
from 
  {sourceSchema}.zc_sex;

--truncate all_ethnicity cascade; 
\echo 'insert into all_ethnicity'
insert into all_ethnicity 
select 
  ethnic_group_c as ethnicity, 
  name as ethnic_description 
from 
  {sourceSchema}.zc_ethnic_group;

--truncate all_marital_status cascade;
\echo 'insert into all_marital_status'
insert into all_marital_status 
select 
  marital_status_c as marital_status, 
  name as marital_status_description 
from 
  {sourceSchema}.zc_marital_status;

--------------reference tables--------------


--------------cohort tables--------------
--truncate cohort; 
\echo 'insert into cohort'
insert into cohort 
select 
  entity_id
from 
  constant.pat_id_to_entity_id
limit {numberpatients};

--------------cohort tables--------------


--------------demographic tables--------------
--truncate demographics; 
\echo 'insert into demographics'
insert into demographics(entity_id, birth_date, death_date, gender, race, ethnicity, city, state, zip, marital_status, living_status)
select 
  entity_id,
  birth_date, 
  death_date, 
  sex_c as gender, 
  --document 
  --1 male 2 female  
  pr.patient_race_c as race, 
  -- foreign key race table 
  ethnic_group_c as ethnicity, 
  city, 
  state_c as state, 
  zip, 
  marital_status_c as marital_status,
  pat_living_stat_c as living_status
from 
  (cohort
   inner join constant.pat_id_to_entity_id as pte using(entity_id)
   inner join {sourceSchema}.patient as pt using(pat_id))
   -- just take the first patient race (which abrogates the need for a 'distinct on entity_id')
  left join {sourceSchema}.patient_race as pr on(pt.pat_id = pr.pat_id and (pr.line = 1 or pr.line is null))
  left join {sourceSchema}.patient_4 as p4 on(pt.pat_id = p4.pat_id)
  left join all_races as rc on pr.patient_race_c = rc.race 
  left join all_genders as gn on pt.sex_c = gn.gender 
  left join all_ethnicity as et on pt.ethnic_group_c = et.ethnicity 
  left join all_marital_status as ma on pt.marital_status_c = ma.marital_status
;

--------------demographic tables--------------


--------------conditions tables--------------
\echo 'insert into conditions'
INSERT INTO conditions (entity_id, visit_id, event_name, event_dttm,
       	                event_code, event_code_vocabulary,
 		                    event_type)
SELECT 
  pat_ent.entity_id, 
  pl.problem_ept_csn, 
  ce.dx_name,
  coalesce(pl.noted_date, pl.date_of_entry),
  UPPER(ecricd.code), 
  'icd_10', 
  'problem_list'  
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {sourceSchema}.problem_list as pl  USING (pat_id)
  JOIN {sourceSchema}.clarity_edg as ce using (dx_id) 
  JOIN {sourceSchema}.edg_current_icd10 ecricd using(dx_id)  
 
UNION

SELECT 
  pat_ent.entity_id, 
  pl.pat_enc_csn_id, 
  ce.dx_name, 
  pl.contact_date, 
  UPPER(ecricd.code), 
  'icd_10', 
  'medical_hx' 
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {sourceSchema}.medical_hx as pl  USING (pat_id)
  JOIN {sourceSchema}.clarity_edg as ce using (dx_id) 
  JOIN {sourceSchema}.edg_current_icd10 ecricd using(dx_id)

UNION

SELECT 
  pat_ent.entity_id, 
  pl.pat_enc_csn_id, 
  ce.dx_name, 
  pl.contact_date, 
  UPPER(ecricd.code), 
  'icd_10', 
  'pat_enc_dx' 
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {sourceSchema}.pat_enc_dx as pl  USING (pat_id)
  JOIN {sourceSchema}.clarity_edg as ce using (dx_id) 
  JOIN {sourceSchema}.edg_current_icd10 ecricd using(dx_id)

UNION

SELECT 
  pat_ent.entity_id,
  hsac.prim_enc_csn_id,
  cedge.dx_name,
  hsac.adm_date_time,
  UPPER(ecricd.code),
  'icd_10',
  'har_dx'
FROM
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {sourceSchema}.hsp_account hsac USING(pat_id)
  JOIN {sourceSchema}.hsp_acct_dx_list hadl USING(hsp_account_id)
  JOIN {sourceSchema}.clarity_edg cedge using (dx_id)
  JOIN {sourceSchema}.edg_current_icd10 ecricd using(dx_id);


--------------conditions tables--------------


--------------encounters tables--------------

--truncate encounters; 
\echo 'insert into encounters'
insert into encounters 
select 
  entity_id, 
  pat_enc_csn_id as visit_id, 
  case when enc_type_c in ('3', '106') then hosp_admsn_time else contact_date end visit_admit_dttm, 
  case when enc_type_c in ('3', '106') then hosp_dischrg_time else contact_date end visit_discharge_dttm, 
  pcp_prov_id as pcp_provider_id, 
  visit_prov_id as visit_provider_id, 
  ordering_prov_id as ordering_provider_id, 
  enc_type_c as encounter_type, 
  department_id 
from 
  {sourceSchema}.pat_enc
  join constant.pat_id_to_entity_id as en using (pat_id)
  --to consider only patient in demographics table
  where entity_id in (select entity_id from cohort);

--------------encounters tables--------------


\include_relative 'labs.sql'

\echo 'insert into medications'
insert into medications(entity_id, visit_id, event_dttm, event_code, event_code_vocabulary, dose, administration_type,medication,route,pharm_subclass, enc_type,discon_time)
select
  distinct -- is this really needed ?
  en.entity_id,		-- entity_id,
  cm.pat_enc_csn_id, 	-- visit_id 
  cm.contact_date, 	-- event_dttm 
  UPPER(norm.rxnorm_code), 	-- event_code
 'rxnorm', 		-- event_code_vocabulary
  med.strength, 	-- dose
  med.form, 		-- administration_type
  med.name, 		-- medication
  route.name, 		-- route
  med.pharm_subclass_c, -- pharm_subclass
  case when enc.enc_type_c in('3', '106') then 'inpatient' else 'outpatient' end, -- enc_type
  discon_time 		-- discon_time
from 
  cohort
  inner join constant.pat_id_to_entity_id en on en.entity_id = cohort.entity_id
  inner join {sourceSchema}.pat_enc enc on enc.pat_id = en.pat_id
  -- slightly different than tzipora's query.  we are joining the pat_enc_csn_id from the pat_enc_curr_meds, not the order_med
  -- perhaps michael has mixed up the semantics of curr_meds and order_meds (must check)
  inner join {sourceSchema}.pat_enc_curr_meds cm on cm.pat_enc_csn_id = enc.pat_enc_csn_id  -- medications prescribed per visit or what they are already taking
  inner join {sourceSchema}.order_med ord on  ord.order_med_id = cm.current_med_id  -- order_med list of meds a patient has been ordered. stores first data/encounter (pat_enc_csn_id) for each medication
  inner join {sourceSchema}.clarity_medication med on med.medication_id  = ord.medication_id -- med info
  inner join {sourceSchema}.rxnorm_codes norm on norm.medication_id = ord.medication_id -- med info
  inner join {sourceSchema}.rx_med_two rx on rx.medication_id  = ord.medication_id -- med info  dose/administration info
  inner join {sourceSchema}.zc_admin_route route on route.med_route_c = rx.admin_route_c  -- medicine administration route (e.g. inhale or injection)
 ;

/*
  -- this is the sameple query from tzipora
SELECT distinct cm.pat_id as Pat_id, cm.pat_enc_csn_ID as enc_id,
       med.name as MEDICATION, cm.CONTACT_DATE as Med_Date,
       med.PHARM_SUBCLASS_C as Pharm_Subclass,norm.RXNORM_CODE as RXNorm,
       med.STRENGTH,med.FORM,--rx.DISCRETE_DOSE
       route.name as route, 
       case 
          when enc.enc_type_c in('3','106') then 'Inpatient' else 'Outpatient' end as enc_type,
FROM   
  `poc_dev.PAT_ENC_CURR_MEDS` cm
   inner join `poc_dev.ORDER_MED` ord on ord.order_med_id=cm.current_med_id
   inner join `hmh-datalake-dev.poc_dev.CLARITY_MEDICATION` med on ord.Medication_ID= med.MEDICATION_ID
   inner join `poc_dev.RXNORM_CODES` norm on med.medication_id=norm.MEDICATION_ID
   inner join `poc_dev.RX_MED_TWO` rx on med.MEDICATION_ID=rx.MEDICATION_ID
   inner join `poc_dev.ZC_ADMIN_ROUTE` route on rx.ADMIN_ROUTE_C=route.MED_ROUTE_C
   inner join `poc_dev.PAT_ENC` enc on ord.PAT_enc_CSN_ID=enc.PAT_ENC_CSN_ID
where 
   ord.DISCON_TIME is null 
*/

\echo 'create index on medications(entity_id)'
create index on medications(entity_id);
\echo 'create index on medications(visit_id)'
create index on medications(visit_id);
\echo 'create index on medications(event_dttm)'
create index on medications(event_dttm);
\echo 'create index on medications(pharm_subclass)'
create index on medications(pharm_subclass);
\echo 'create index on medications(event_code)'
create index on medications(event_code);

------------------concepts table-----------------------
\echo 'insert into concepts' 
INSERT into concepts (
  concept_code, concept_text, concept_system, 
  concept_display, concept_start_date, 
  concept_end_date, concept_resource, 
  hmh_concept_code
) 
values 
  (
    '35094-2', 'Blood pressure panel', 
    'LOINC', 'blood pressure', '2023-01-01' :: timestamp, 
    null, 'vitals', '5'
  ), 
  (
    'LP35925-4', 'Body mass index (BMI)', 
    'LOINC', 'BMI', '2023-01-01' :: timestamp, 
    null, 'vitals', '301070'
  ), 
  (
    '29463-7', 'Body weight', 'LOINC', 
    'weight', '2023-01-01' :: timestamp, null, 
    'vitals', '14'
  ), 
  (
    'C0232117', 'Pulse rate', 'SNOMED CT', 
    'pulse', '2023-01-01' :: timestamp, null, 
    'vitals', '8'
  ), 
  (
    '8867-4', 'Heart rate', 'LOINC', 'heart rate', 
    '2023-01-01' :: timestamp, null, 'vitals', 
    '301240'
  );

------------------vitals table-----------------------

\echo 'truncate vitals' 
truncate table vitals;
\echo 'insert into vitals' 
INSERT into vitals (
  entity_id, visit_id, event_name, event_dttm, 
  event_code, event_code_vocabulary, 
  event_value_string, event_concept_code, 
  event_concept_text, event_concept_system, 
  fsd_id, record_date
) 
SELECT 
  pat_ent.entity_id as entity_id, 
  enc.pat_enc_csn_id as visit_id, 
  conc.concept_display, 
  flowm.recorded_time as event_dttm, 
  flowm.flo_meas_id as event_code, 
  'FLO_MEAS_ID' as event_code_vocabulary, 
  flowm.meas_value as event_value_string, 
  conc.concept_code, 
  conc.concept_text, 
  conc.concept_system, 
  flowm.fsd_id as fsd_id, 
  flowr.record_date as record_date 
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {sourceSchema}.pat_enc enc USING (pat_id)
  JOIN {sourceSchema}.ip_flwsht_rec flowr USING(inpatient_data_id)
  JOIN {sourceSchema}.ip_flwsht_meas flowm USING(fsd_id)
  JOIN concepts as conc on flowm.flo_meas_id = conc.hmh_concept_code;


------------------------procedures table--------------------------------
INSERT into procedures (
  entity_id, visit_id, 
  event_code, event_dttm, 
  event_type, event_desc, 
  enc_type, proc_count 
)
SELECT 
  pat_ent.entity_id as entity_id,
  enc.pat_enc_csn_id as visit_id,
  cpt_code as event_code,
  service_date event_dttm,
  CASE 
    when pb.cpt_code between '99202' and '99499' then 'E&M'
    when pb.cpt_code between '00100' and '01999' then 'Anesthesia'
    when pb.CPT_CODE between '10021' and '69990' then 'Surgery'
    when pb.CPT_CODE between '70010' and '79999' then 'Radiology'
    when pb.CPT_CODE between '80047' and '89398' then 'Path/Lab'
    when pb.CPT_CODE between '90281' and '99607' then 'Medicine Svcs/Procs'
  end as event_type,
  eap.proc_name as event_desc,
  enc.enc_type_c as enc_type,
  sum(pb.PROCEDURE_QUANTITY) as proc_count
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN {sourceSchema}.pat_enc enc USING (pat_id)
  JOIN {sourceSchema}.arpb_transactions pb USING (pat_enc_csn_id)
  LEFT JOIN {sourceSchema}.clarity_eap eap USING(proc_id)
WHERE 
(
  (pb.CPT_CODE between '99202' and '99499')
  OR (pb.CPT_CODE between '00100' and '01999')
  OR (pb.CPT_CODE between '10021' and '69990')
  OR (pb.CPT_CODE between '70010' and '79999')
  OR (pb.CPT_CODE between '80047' and '89398')
  OR (pb.CPT_CODE between '90281' and '99607')
)
AND upper(pb.cpt_code) ~'[A-Z]'
AND length(pb.cpt_code) = 5
GROUP BY pat_ent.entity_id, enc.pat_enc_csn_id, pb.cpt_code,service_date,enc.enc_type_c,eap.proc_name
HAVING sum(pb.PROCEDURE_QUANTITY) > 0

------------------------procedures table--------------------------------

