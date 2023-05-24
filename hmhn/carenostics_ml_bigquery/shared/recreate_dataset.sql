
if exists(select schema_name from INFORMATION_SCHEMA.SCHEMATA where schema_name = '$DATASET')
then
  drop schema $DATASET cascade;
end if ;

-- "drop schema if exists" fails when run from a query in the browser (when the dataset does not exist)
-- drop schema if exists $DATASET cascade ;

create schema $DATASET ;

