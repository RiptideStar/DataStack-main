declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

drop table if exists medications;

create table medications (
  entity_id int not null, 
  visit_id int not null, 
  event_dttm datetime not null, 
  event_code string not null, 
  event_code_vocabulary string not null, 
  dose string,
  sig_text string,
  administration_type string, 
  medication string, 
  route string, 
  pharm_subclass int,  
  enc_type string, 
  discon_time datetime 
);


insert into medications(entity_id, visit_id, event_dttm, event_code, event_code_vocabulary, dose, sig_text, administration_type,medication,route,pharm_subclass, enc_type,discon_time)
select
  distinct -- is this really needed ?
  en.entity_id,         -- entity_id,
  cast(cm.pat_enc_csn_id as int),       -- visit_id 
  cm.contact_date,      -- event_dttm 
  UPPER(norm.rxnorm_code),      -- event_code
 'rxnorm',              -- event_code_vocabulary
  med.strength,         -- dose
  sig.sig_text,
  med.form,             -- administration_type
  med.name,             -- medication
  route.name,           -- route
  cast(med.pharm_subclass_c as int), -- pharm_subclass
  case when enc.enc_type_c in('3', '106') then 'inpatient' else 'outpatient' end, -- enc_type
  discon_time           -- discon_time
from 
  cohort
  inner join constant.pat_id_to_entity_id en on en.entity_id = cohort.entity_id

  inner join $HMHN.PAT_ENC enc on enc.pat_id = en.pat_id
  -- slightly different than tzipora's query.  we are joining the pat_enc_csn_id from the pat_enc_curr_meds, not the order_med
  -- perhaps michael has mixed up the semantics of curr_meds and order_meds (must check)
  inner join $HMHN.PAT_ENC_CURR_MEDS cm on cm.pat_enc_csn_id = enc.pat_enc_csn_id  -- medications prescribed per visit or what they are already taking
  inner join $HMHN.ORDER_MED ord on  ord.order_med_id = cm.current_med_id  -- order_med list of meds a patient has been ordered. stores first data/encounter (pat_enc_csn_id) for each medication

  inner join $HMHN.ORDER_MED_SIG sig on ord.ORDER_MED_ID = sig.ORDER_ID
  inner join $HMHN.CLARITY_MEDICATION med on med.medication_id  = ord.medication_id -- med info
  inner join $HMHN.RXNORM_CODES norm on norm.medication_id = ord.medication_id -- med info
  inner join $HMHN.RX_MED_TWO rx on rx.medication_id  = ord.medication_id -- med info  dose/administration info
  inner join $HMHN.ZC_ADMIN_ROUTE route on route.med_route_c = rx.admin_route_c  -- medicine administration route (e.g. inhale or injection)
 ;




select utils.formatInt(count(*)) as `medications size` from medications ;

if DEBUG
then
  select * from medications
  order by entity_id
  limit 10;
end if ;



