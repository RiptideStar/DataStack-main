declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

drop table if exists vitals;

create table vitals (
  entity_id int not null, 
  visit_id int not null, 
  event_name string,
  event_dttm datetime not null, 
  event_code string not null, 
  event_code_vocabulary string not null, 
  event_value_string string, 
  event_concept_code string not null,
  event_concept_system string not null,
  event_concept_text string,
  fsd_id string, 
  record_date datetime
);


INSERT into vitals (
  entity_id, visit_id, event_name, event_dttm, 
  event_code, event_code_vocabulary, 
  event_value_string, event_concept_code, 
  event_concept_text, event_concept_system, 
  fsd_id, record_date
) 
SELECT 
  pat_ent.entity_id, 
  cast(enc.pat_enc_csn_id as int), 
  conc.concept_display, 
  flowm.recorded_time, 
  flowm.flo_meas_id, 
  'FLO_MEAS_ID', 
  flowm.meas_value , 
  conc.concept_code, 
  conc.concept_text, 
  conc.concept_system, 
  flowm.fsd_id, 
  flowr.record_date 
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN $HMHN.PAT_ENC ENC USING (pat_id)
  JOIN $HMHN.IP_FLWSHT_REC flowr USING(inpatient_data_id)
  JOIN $HMHN.IP_FLWSHT_MEAS flowm USING(fsd_id)
  JOIN concepts as conc on flowm.flo_meas_id = conc.hmh_concept_code;





select utils.formatInt(count(*)) as `vitals size` from vitals ;

if DEBUG
then
  select * from vitals
  order by entity_id
  limit 10;
end if ;
