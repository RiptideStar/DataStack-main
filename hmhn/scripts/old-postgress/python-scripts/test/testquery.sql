-- first query
-- \timing on|off  - show execution times
-- \schema on|off  - show schema from both big query an data frame
-- \echo ....      - echo the message 
-- \skip on|off    - skip processing till \skip off
-- \exit           - exit processing of script  
-- \intfmt c1;c2;c3 ...    semi colon separated list of int formats by columns (, for comma separated thousands).  
--                         if no ';', the same is applied to all int columns (default is '')
-- \floatfmt c1;c2;c3 ...  semi colon separated list of int formats by columns (.1f for one decimal)
--                         if no ';' the same is applied to all float columns  (default is 'g')
-- \headers c1;c2;c3 ...   column headers to use

\timing on
\schema on

\skip off
\headers Label;Count;%
\floatfmt .1f
\intfmt ,
select label, count, percent
from `ckd_table.summary` ;

\skip off
SELECT entity_id,visit_id,event_dttm,event_code,event_code_vocabulary,dose,administration_type,medication,
       route,pharm_subclass,enc_type,discon_time
FROM `ckd_table.medications`
WHERE entity_id = 6441553 AND pharm_subclass IN (2770,3750,3610,3615) ORDER BY event_dttm
limit 5 ; 

\skip off
SELECT entity_id,medication,route
FROM `ckd_table.medications`
WHERE entity_id = 6441553 AND pharm_subclass IN (2770,3750,3610,3615) ORDER BY event_dttm
limit 3 ;

