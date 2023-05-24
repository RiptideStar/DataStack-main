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

drop table if exists labs;
create table labs (
  entity_id bigint not null, 
  visit_id bigint not null, 
  event_name text not null, 
  event_dttm timestamp(0) null, 
  component_id bigint not null, 
  event_code text null, 
  event_code_vocabulary text not null, 
  event_value_string text null, 
  event_value_numeric bigint null, 
  event_unit text null,
  proc_name text null,
  base_name text null
  
);

--truncate labs; 
\echo 'insert into labs'
insert into labs(entity_id, visit_id, event_name, event_dttm,
       	         component_id, event_code, event_code_vocabulary,
 		 event_value_string, event_value_numeric, event_unit,
		 proc_name, base_name)
select 
  en.entity_id, 
  ores.pat_enc_csn_id as visit_id, 
  cc.common_name as event_name, 
  ores.result_date as event_dttm, 
  ores.component_id, 
  UPPER(cc.loinc_code) as event_code, 
  'loinc' as event_code_vocabulary, 
  ores.ord_value as event_value_string, 
  ores.ord_num_value as event_value_numeric, 
  cc.dflt_units as event_unit,
  eap.proc_name,
  cc.base_name
from 
  cohort
  inner join constant.pat_id_to_entity_id en using(entity_id)
  inner join {sourceSchema}.pat_enc enc using(pat_id)
  inner join {sourceSchema}.order_proc opr using(pat_enc_csn_id)
  inner join {sourceSchema}.order_results ores using(order_proc_id)
  inner join {sourceSchema}.clarity_component cc using(component_id)
  inner join {sourceSchema}.clarity_eap eap using(proc_id)
where
  -- "final" or "edited final" (ok to ignore the few nulls).  about 2.5% of the entries
  ores.lab_status_c in (3, 5) 
  ;

\echo 'create index on labs(entity_id)'
create index on labs(entity_id);
\echo 'create index on labs(visit_id)'
create index on labs(visit_id);
\echo 'create index on labs(event_dttm)'
create index on labs(event_dttm);
\echo 'create index on labs(event_code)'
create index on labs(event_code);
\echo 'create index on labs(component_id)'
create index on labs(component_id);
\echo 'create index on labs(proc_name)'
create index on labs(proc_name);
\echo 'create index on labs(base_name)'
create index on labs(base_name);
