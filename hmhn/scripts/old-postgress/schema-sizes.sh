#!/bin/bash

$(dirname "${BASH_SOURCE[0]}")/run-query.sh <<EOF
SELECT schema_name, 
       to_char(sum(table_size)/1073741824 ,'FM999,999') "GB",
       round((sum(table_size) / database_size) * 100) "% of entire database"
FROM (
  SELECT pg_catalog.pg_namespace.nspname as schema_name,
         pg_relation_size(pg_catalog.pg_class.oid) as table_size,
         sum(pg_relation_size(pg_catalog.pg_class.oid)) over () as database_size
  FROM   pg_catalog.pg_class
     JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
) t
GROUP BY schema_name, database_size
order by sum(table_size) desc
EOF
