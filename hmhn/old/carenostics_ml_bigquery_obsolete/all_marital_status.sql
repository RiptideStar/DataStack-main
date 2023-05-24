\timing off

\skip off
drop table if exists all_marital_status ;

create table all_marital_status (
  marital_status int not null, 
  marital_status_description string not null
) ;


\time_as 'insert into all_marital_status'
insert into all_marital_status(marital_status, marital_status_description)
select 
  cast(marital_status_c as int),
  name
from 
  {hmhn}.ZC_MARITAL_STATUS;


\skip off
select * from all_marital_status order by marital_status limit 10;
select count(*)  `Number marital status` from all_marital_status;
