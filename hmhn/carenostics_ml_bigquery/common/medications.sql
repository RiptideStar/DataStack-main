declare DEBUG boolean default $DEBUG ;

set @@dataset_id = '$DATASET' ;

create or replace 
function $DATASET.inferDate(d1 datetime, d2 datetime, d3 datetime, offset float64)
returns datetime
as 
   (coalesce(d1, d2, d3, datetime_add(date '1840-12-31', interval cast(offset as int) day))) ;

create or replace 
function $DATASET.inferEndDate(e1 datetime, e2 datetime, e3 datetime, st datetime)
returns datetime
as 
   (coalesce(e1, e2, e3, datetime_add(st, interval 30  day))) ;



drop table if exists medications;

create table medications (
  entity_id int not null, 
  visit_id int not null, 
  start_time datetime not null, 
  end_time datetime,  -- can be null (eventhough it should not be)
  effective_end_time datetime not null, -- end time to use when doing analysis
  event_code string not null, 
  event_code_vocabulary string not null, 
  dose string,
  sig_text string,
  administration_type string,
  medication_id int not null,
  medication string, 
  route string, 
  pharm_subclass int,  
  enc_type string
);

insert into medications(entity_id, visit_id, start_time, end_time, effective_end_time, event_code, event_code_vocabulary, dose, sig_text,
                        administration_type,medication,medication_id,route,pharm_subclass, enc_type)
select
  distinct -- saves about 5%
  en.entity_id,         -- entity_id,
  cast(ord.pat_enc_csn_id as int),       -- visit_id 
  $DATASET.inferDate(order_start_time, start_date, ordering_date, ord.pat_enc_date_real),
  coalesce(end_date, discon_time, order_end_time),
  $DATASET.inferEndDate(end_date, discon_time, order_end_time,
  		        $DATASET.inferDate(order_start_time, start_date, ordering_date, ord.pat_enc_date_real)),
  UPPER(norm.rxnorm_code),      -- event_code
 'rxnorm',              -- event_code_vocabulary
  med.strength,         -- dose
  sig.sig_text,         -- sig_text
  med.form,             -- administration_type
  med.name,             -- medication,
  cast(ord.medication_id as int),  -- medication_id
  route.name,           -- route
  cast(med.pharm_subclass_c as int), -- pharm_subclass
  case when enc.enc_type_c in('3', '106') then 'inpatient' else 'outpatient' end -- enc_type
from 
  cohort
  inner join constant.pat_id_to_entity_id en on en.entity_id = cohort.entity_id
  inner join $HMHN.ORDER_MED ord on  ord.pat_id = en.pat_id
  inner join $HMHN.PAT_ENC enc on enc.pat_enc_csn_id = ord.pat_enc_csn_id -- only used for the encounter type
  inner join $HMHN.ORDER_MED_SIG sig on sig.ORDER_ID = ord.ORDER_MED_ID
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



