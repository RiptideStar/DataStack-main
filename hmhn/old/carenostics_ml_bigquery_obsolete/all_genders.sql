\timing off

\skip off
drop table if exists all_genders ;

create table all_genders (
  gender int not null, 
  gender_description string not null
) ;


\time_as 'insert into all_genders'
insert into all_genders(gender, gender_description)
select 
  cast(rcpt_mem_sex_c as int),
  name
from 
  {hmhn}.ZC_SEX;


\skip off
select * from all_genders order by gender limit 10;
select count(*)  `Number Genders` from all_genders;
