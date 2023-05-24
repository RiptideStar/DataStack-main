/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to perform copy the tables from the source to the destination
                    normalized table.
                    
Author:             Michael Greenberg, Vikram Anand
***************************************************************************************************/ 


\timing on
\echo 'drop ip_flwsht_rec'
drop table if exists ip_flwsht_rec;
\echo 'drop ip_flwsht_meas'
drop table if exists ip_flwsht_meas;

-- 36 million
\echo 'copy table ip_flwsht_rec'
create table ip_flwsht_rec as select * from "{sourceSchema}"."IP_FLWSHT_REC"  ;
\echo 'create primary key for ip_flwsht_rec'
alter table ip_flwsht_rec ADD PRIMARY KEY (fsd_id);
\echo 'create index on ip_flwsht_rec(pat_id)'
create index on ip_flwsht_rec(pat_id) ;

-- 4,500 million - complete
--   262 million - limiting to the specific ids
\echo 'copy table ip_flwsht_meas'
create table ip_flwsht_meas as
select * from "{sourceSchema}"."IP_FLWSHT_MEAS"
where
  FLO_MEAS_ID in (
  '5', -- blood pressure
  '301070', -- BMI
  '14', -- body weight
  '8', -- pulse
  '301240' -- heart weight
  )
;

\echo 'create PK ip_flwsht_mea'
-- note:  we will have gaps in the 'line' values becuase we are not importing all the measures
alter table ip_flwsht_meas add primary key(fsd_id, line) ;
\echo 'create index on ip_flwsht_meas(flo_meas_id)'
create index on ip_flwsht_meas(flo_meas_id) ;
