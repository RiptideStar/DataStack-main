set @@dataset_id = '$DATASET' ;
select table_id, row_count 
from __TABLES__ 
order by 
  row_count desc;

