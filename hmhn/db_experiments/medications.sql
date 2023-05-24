create table cohort (
  entity_id bigint primary key
);

create table medications (
  entity_id bigint not null, 
  visit_id bigint not null, 
  event_dttm timestamp(0) not null, 
  event_code text not null, 
  event_code_vocabulary text not null, 
  dose text null, 
  administration_type text null, 
  medication text null, 
  route text null, 
  pharm_subclass bigint null,  
  enc_type text null, 
  discon_time timestamp(0) null
);


\timing on

\echo 'insert into cohort'
insert into cohort 
select 
  entity_id
from 
  {sourceSchema}.pat_id_to_entity_id
limit {numberpatients};


\echo 'insert into medications'

-- 36,122,369 - not distinct - 601
-- index after - 681
-- 35,828,052 distinct 534
insert into medications(entity_id, visit_id, event_dttm, event_code, event_code_vocabulary, dose, administration_type,medication,route,pharm_subclass, enc_type,discon_time)
select
  distinct
  en.entity_id,		-- entity_id,
  cm.pat_enc_csn_id, 	-- visit_id 
  cm.contact_date, 	-- event_dttm 
  norm.rxnorm_code, 	-- event_code
 'rxnorm', 		-- event_code_vocabulary
  med.strength, 	-- dose
  med.form, 		-- administration_type
  med.name, 		-- medicatio
  route.name, 		-- route
  med.pharm_subclass_c, -- pharm_subclass
  case when enc.enc_type_c in('3', '106') then 'inpatient' else 'outpatient' end, -- enc_type
  discon_time 		-- discon_time
from 
  cohort
  inner join {sourceSchema}.pat_id_to_entity_id en on en.entity_id = cohort.entity_id
  inner join {sourceSchema}.pat_enc enc on enc.pat_id = en.pat_id

  inner join {sourceSchema}.pat_enc_curr_meds cm on cm.pat_enc_csn_id = enc.pat_enc_csn_id  -- medications prescribed per visit
  inner join {sourceSchema}.order_med ord on  ord.order_med_id = cm.current_med_id  -- order_med list of meds a patient has been ordered. stores first data/encounter (pat_enc_csn_id) for each medication

  inner join {sourceSchema}.clarity_medication med on med.medication_id  = ord.medication_id -- med info
  inner join {sourceSchema}.rxnorm_codes norm on norm.medication_id = ord.medication_id -- med info
  inner join {sourceSchema}.rx_med_two rx on rx.medication_id  = ord.medication_id -- med info  dose/administration info
  inner join {sourceSchema}.zc_admin_route route on route.med_route_c = rx.admin_route_c  -- medicine administration route (e.g. inhale or injection)
 ;

create index idx_medications_entity_id on medications(entity_id);
create index idx_medications_visit_id on medications(visit_id);
create index idx_medications_event_dttm on medications(event_dttm);
create index idx_medications_pharm_subclass on medications(pharm_subclass);
create index idx_medications_event_code on medications(event_code);




/*
insert into medications(entity_id, visit_id, event_dttm, event_code, event_code_vocabulary, dose, administration_type,medication,route,pharm_subclass, enc_type,discon_time)
select
--  distinct
  en.entity_id,		-- entity_id,
  cm.pat_enc_csn_id, 	-- visit_id 
  cm.contact_date, 	-- event_dttm 
  norm.rxnorm_code, 	-- event_code
 'rxnorm', 		-- event_code_vocabulary
  med.strength, 	-- dose
  med.form, 		-- administration_type
  med.name, 		-- medicatio
  route.name, 		-- route
  med.pharm_subclass_c, -- pharm_subclass
  case when enc.enc_type_c in('3', '106') then 'inpatient' else 'outpatient' end, -- enc_type
  discon_time 		-- discon_time
from 
  -- cohort
  --inner join {sourceSchema}.pat_id_to_entity_id en on en.entity_id = cohort.entity_id
  -- inner join {sourceSchema}.pat_enc enc on enc.pat_id = en.pat_id

  {sourceSchema}.pat_enc_curr_meds cm  -- medications prescribed per visit
  inner join {sourceSchema}.pat_id_to_entity_id en on en.pat_id = cm.pat_id
  inner join {sourceSchema}.order_med ord on  ord.order_med_id = cm.current_med_id  -- order_med list of meds a patient has been ordered. stores first data/encounter (pat_enc_csn_id) for each medication

  inner join {sourceSchema}.clarity_medication med on med.medication_id  = ord.medication_id -- med info
  inner join {sourceSchema}.rxnorm_codes norm on norm.medication_id = ord.medication_id -- med info
  inner join {sourceSchema}.rx_med_two rx on rx.medication_id  = ord.medication_id -- med info  dose/administration info
  inner join {sourceSchema}.zc_admin_route route on route.med_route_c = rx.admin_route_c  -- medicine administration route (e.g. inhale or injection)
where
  en.entity_id in (select entity_id from cohort)

 ;
*/
