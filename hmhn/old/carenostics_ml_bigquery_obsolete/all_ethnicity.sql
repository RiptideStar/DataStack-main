\timing off

\skip off
drop table if exists all_ethnicity ;

create table all_ethnicity (
  ethnicity int not null, 
  ethnicity_description string not null
) ;


\time_as 'insert into all_ethnicity'
insert into all_ethnicity(ethnicity, ethnicity_description)
select 
  cast(ethnic_group_c as int),
  name
from 
  {hmhn}.ZC_ETHNIC_GROUP;


\skip off
select * from all_ethnicity order by ethnicity limit 10;
select count(*)  `Number ethnicity` from all_ethnicity;
