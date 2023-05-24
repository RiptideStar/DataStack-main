-- delete the destination schema if it already exists
drop schema if exists {newSchema} cascade ;

-- create the destiantion schema
create schema {newSchema} ;
