/*  this stores some useful stored functions that are have nothing to do with medical information ...
 *  for example ... data formatting
*/

if exists(select schema_name from INFORMATION_SCHEMA.SCHEMATA where schema_name = 'utils')
then
  drop schema utils cascade;
end if ;

create schema utils ;

create or replace 
function utils.deltaPercent(v2 int, v1 int)
returns float64
as 
  (case
    when v1 is null then null
    when v2 is null then null
    when v1 = 0 then null
    else (v2-v1)*100/v1
  end)
;

create or replace 
function utils.deltaAbsolute(v2 int, v1 int)
returns int
as 
  (case 
    when v1 is null then null
    when v2 is null then null
    else v2-v1
  end)
;

create or replace 
function utils.formatInt(v1 int)
returns string
as 
  (case
    when v1 is null then ''
    else format("%'14d",v1)
  end)
;

create or replace 
function utils.formatPct(pct float64)
returns string
as 
  (case
    when pct is null then ''
    else format("%'6.1f",pct)  -- for upto  -100.0
  end)
;
