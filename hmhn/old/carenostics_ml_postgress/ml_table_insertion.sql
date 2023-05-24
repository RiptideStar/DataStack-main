/***************************************************************************************************
Copyright (C) Carenostics, Inc - All Rights Reserved Unauthorized copying of this file, 
via any medium is strictly prohibited 

Proprietary and Confidential

Description:        This SQL is used to build and update the tables required for ML analysis. This 
                    includes the UACR analysis, EGFR Analysis, CKD Analysis and creation of a 
                    a flat table with all values required for analytics.
Author:             Michael Greenberg, Vikram Anand
***************************************************************************************************/                                            

\timing on
\include_relative 'uacr_analysis.sql'
\include_relative 'egfr_analysis.sql'
\include_relative 'ckd_analysis.sql'
\include_relative 'flt_analysis.sql'
\include_relative 'summary.sql'
