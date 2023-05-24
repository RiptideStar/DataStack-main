declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;

drop table if exists procedures;

create table procedures (
  entity_id int not null,
  visit_id int not null, 
  event_code string not null,
  event_dttm datetime not null, 
  event_type string not null,
  event_desc string,
  enc_type string not null, 
  proc_count int not null

);


INSERT into procedures (
  entity_id, visit_id, 
  event_code, event_dttm, 
  event_type, event_desc, 
  enc_type, proc_count 
)
SELECT 
  pat_ent.entity_id,
  cast(enc.pat_enc_csn_id as int),
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
  cast(sum(pb.PROCEDURE_QUANTITY) as int64) as proc_count
FROM 
  cohort
  JOIN constant.pat_id_to_entity_id pat_ent USING(entity_id)
  JOIN $HMHN.PAT_ENC enc USING (pat_id)
  JOIN $HMHN.ARPB_TRANSACTIONS pb USING (pat_enc_csn_id)
  LEFT JOIN $HMHN.CLARITY_EAP eap USING(proc_id)
WHERE 
(
  (pb.CPT_CODE between '99202' and '99499')  -- one satisfying code is 0011A
  OR (pb.CPT_CODE between '00100' and '01999')
  OR (pb.CPT_CODE between '10021' and '69990')
  OR (pb.CPT_CODE between '70010' and '79999')
  OR (pb.CPT_CODE between '80047' and '89398')
  OR (pb.CPT_CODE between '90281' and '99607')
)
AND regexp_contains(pb.cpt_code, '[A-Za-z]')   -- was upper(pb.cpt_code) ~'[A-Z]'  which is just contains a letter
AND length(pb.cpt_code) = 5
GROUP BY pat_ent.entity_id, enc.pat_enc_csn_id, pb.cpt_code,service_date,enc.enc_type_c,eap.proc_name
HAVING sum(pb.PROCEDURE_QUANTITY) > 0 ;

------------------------procedures table--------------------------------





select utils.formatInt(count(*)) as `procedures size` from procedures ;

if DEBUG
then
  select * from procedures
  order by entity_id
  limit 10;
end if ;



