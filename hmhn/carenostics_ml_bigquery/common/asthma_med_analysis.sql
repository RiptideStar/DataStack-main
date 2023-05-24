declare DEBUG boolean default $DEBUG ;
set @@dataset_id = '$DATASET' ;


create or replace table asthma_meds(
  entity_id int not null, 
  visit_id int not null, 
  start_time datetime not null, 
  effective_end_time datetime not null,
  event_code string not null, 
  event_code_vocabulary string not null, 
  dose string,
  sig_text string,
  administration_type string, 
  medication_id int not null,
  medication string, 
  route string, 
  pharm_subclass int,  
  enc_type string, 
  drug_class string
) ;

insert into asthma_meds(entity_id, visit_id, start_time,  effective_end_time, event_code, event_code_vocabulary, dose,
       	    	            administration_type, medication_id, medication, route, pharm_subclass, enc_type,
			    drug_class, sig_text)
select  entity_id, visit_id, start_time, effective_end_time, event_code, event_code_vocabulary, medications.dose,
       	medications.administration_type, medications.medication_id, medication, medications.route, pharm_subclass, enc_type, 
	drug_class, sig_text
FROM
  medications 
  JOIN constant.asthma_meds_map asth ON medications.medication_id = asth.medication_id
  -- INNER JOIN constant.asthma_meds_map asth ON medications.event_code = asth.rxnorm_code
;

select (select utils.formatInt(count(*)) from asthma_meds) `total asthma meds`,
       (select utils.formatInt(count(distinct entity_id)) from asthma_meds) `patients with asthma meds`
       ;
       
