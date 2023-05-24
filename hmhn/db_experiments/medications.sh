ML=ml_test
NORMALIZED=mlg_normalized
NUM_PATIENTS=1000000

../scripts/run-sql.sh --newSchema=$ML ./recreate-empty-schema.sql
../scripts/run-sql.sh --schema=$ML --sourceSchema=$NORMALIZED --numberpatients=$NUM_PATIENTS ./medications.sql
