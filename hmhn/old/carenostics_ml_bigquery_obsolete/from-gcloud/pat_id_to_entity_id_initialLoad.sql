select row_number() over (order by pat_id asc) as entity_id, pat_id 
from `hmh-datalake-prod-c5b4.CLARITY.PATIENT` order by pat_id asc
