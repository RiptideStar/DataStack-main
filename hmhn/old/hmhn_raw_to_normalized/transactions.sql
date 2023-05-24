/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to perform copy the tables from the source to the destination
                    normalized table.
                    
Author:             Michael Greenberg, Vikram Anand
***************************************************************************************************/ 


\timing on
\echo 'drop arpb_transactions'
drop table if exists arpb_transactions;

\echo 'copy table arpb_transactions'
create table arpb_transactions as select * from "{sourceSchema}"."ARPB_TRANSACTIONS"  ;
\echo 'create primary key for arpb_transactions'
alter table arpb_transactions ADD PRIMARY KEY (tx_id) ;
\echo 'create index on arpb_transactions(proc_id)'
create index on arpb_transactions(proc_id) ;
\echo 'create index on arpb_transactions(pat_enc_csn_id)'
create index on arpb_transactions(pat_enc_csn_id) ;
