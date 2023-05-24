SEE CREATE_ML.sh

--sourceSchema=hmhn_normalisedThis folder consists of five files: 
	1. base_table_creation.sql
	2. base_table_insertion.sql
	3. ml_table_creation.sql
	4. ml_table_insertion.sql
	5. recreate-empty-schema.sql
	6. run-sql.sh

Commands to run the script files.

	1. export PGPASSWORD="<password>"
		./run-sql.sh --newSchema=carenostics_ml_testing ./recreate-empty-schema.sql

	2. The database generation process has the following steps

    copy the raw data from hmhn (currently in the schema named ‘copy’) to a ‘normalized’ database.  The normalize database fixes the case of the table names and adds primary keys and indexes.  Contains data for all the patient

    generate the ml_database (ideally hospital independent).  Contains a subset of the patients

        create the ‘base tables’
            select the cohort (number of patient)
            copy data for those patients from the normalized to the base_tables

        create the ml tables
            analyze the base tables and save results

	4. There is a script of ours   hmhn/scripts/run-sql.sh.   All db processes are invoked via this script.

    	parameter substitution   e.g.   --source-schema=copy
    	setting the default schema.  e.g. --schema=michael_db

    	for the DB password, either
        	export PGPASSWORD=xxxx    OR

        ~/.db_setup.sh … this is sourced as part of running the script

	5. Simple db-generation:

    	hmhn/create-normalized.sh  <name_of_normalize_schema_to_write_to>    (uses ‘copy’ as the source)
        hmhn_raw_to_normalized/create-hmhn-normalized.sh -n=$NORM   

    	hmhn/create-ml.sh <ml_schema> <normalized_schema> <number_of_patients>
        carenostics_ml/create_ml.sh  --ml=${ML}_$PTS --normalized=${NORM} --number-patients=$PTS -all
	
	6. These save logs to hmhn/logs



