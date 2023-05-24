create or replace 
function `{dataset}`.computeN18(event_code string) 
returns string
as 
  -- theoretically, this is a comma separated list ... but ... we don't see to
  -- actually have any such data.  make sure the N18.x is delimited by word boundaries
  -- by default, regexp_extract returns the first capture group
  -- there will never be more than one N18 code
  (regexp_extract(event_code, '\\b(N18[.][0-9]+)\\b'))
;

create or replace 
function `{dataset}`.computeCkdDxStage(n18 string) 
returns float64
as 
 (case
      when n18 = 'N18.1' then 1
      when n18 = 'N18.2' then 2
      when n18 = 'N18.3' then 3 
      when n18 = 'N18.30' then 3 -- unspecified 3
      when n18 = 'N18.31' then 3 -- 3a
      when n18 = 'N18.32' then 3.5  -- stage 3b
      when n18 = 'N18.4' then 4 -- do we want to match all N18.4 ?
      when n18 = 'N18.5' then 5
      when n18 = 'N18.6' then 5
      when n18 = 'N18.9' then 3 -- unknown stage
      else null
  end
 ) ;

create or replace table ckd_dx_codes(
    entity_id int not null,
    visit_id int,
    event_name string,
    event_dttm datetime, 
    event_code string, 
    event_code_vocabulary string, 
    event_type string,
    n18 string,
    stage float64 not null,
    is_abnormal boolean not null
) ;

\time_as 'insert into ckd_dx_codes'
insert into ckd_dx_codes(entity_id, visit_id, event_name, event_dttm, 
                         event_code, event_code_vocabulary, 
                         event_type, n18, stage, is_abnormal)
select
    entity_id,
    cast(visit_id as integer) as visit_id,
    event_name,
    event_dttm,
    event_code, 
    event_code_vocabulary, 
    event_type ,
    {dataset}.computeN18(event_code),
    {dataset}.computeCkdDxStage(`{dataset}`.computeN18(event_code)),
    {dataset}.computeCkdDxStage(`{dataset}`.computeN18(event_code)) >= 3
from conditions
where  
  `{dataset}`.computeCkdDxStage(`{dataset}`.computeN18(event_code)) is not null
  ;


\intfmt ,
select count(entity_id) `Number of ckd_dx_codes`
from ckd_dx_codes ;

\intfmt ,
select count(entity_id) `Number of abnormal ckd_dx_codes`
from ckd_dx_codes where is_abnormal;

\skip on
\intfmt ,
select n18, count(*) `Count` from ckd_dx_codes group by n18 order by n18;
select n18, count(distinct(entity_id)) `Count distinct entity_id` from ckd_dx_codes group by n18 order by n18;
