const utils = require('./utils');
const { Command, CommanderError, storeOptionsAsProperties, exitOverride, InvalidOptionArgumentError } = require('commander');
const { table, getBorderCharacters } = require('table');

const { Client } = require('pg');
const Cursor = require('pg-cursor')

const client = new Client({
    user: 'postgres',
    host: '10.152.17.12',
    database: 'postgres',
    password: 'Sff3(#d-a4MKh^MT',
    port: 5432
});


const program = new Command();

const MED_COLUMNS = ['entity_id',
    'visit_id',
    'event_dttm',
    'enc_type',
    'medication',
    'route',
    'administration_type',
    'dose',
    'event_code',
    'event_code_vocabulary',
    'pharm_subclass',
    'discon_time'];

const LAB_COLUMNS = ['entity_id',
'visit_id',
'event_name',
'event_dttm',
'component_id',
'event_code',
'event_code_vocabulary',
'event_value_string',
'event_value_numeric',
'event_unit',
];

program.command('medQuery')
    .requiredOption('-s|--schema <schema>', 'schema to use', utils.myParseString)
    .option('-l|--limit <rows>', 'number rows', utils.myParseInt, 10)
    .action(async function (cmdObj) {
        let schema = cmdObj.schema;


        let query = `SELECT ${MED_COLUMNS.join(',')} from ${schema}.medications order by entity_id, visit_id limit ${cmdObj.limit}`;
        // let res = await client.query(query);

        let res = await client.query({ text: query, rowMode: 'array' });

        utils.displayResultSet(res);
    });

program.command('medCursorQuery')
    .requiredOption('-s|--schema <schema>', 'schema to use', utils.myParseString)
    .option('-l|--limit <rows>', 'number rows', utils.myParseInt, 100)
    .action(async function (cmdObj) {
        let schema = cmdObj.schema;

        let query = `SELECT ${MED_COLUMNS.join(',')} from ${schema}.medications order by entity_id, visit_id`;
        let fields = (await client.query(query + ' limit 0')).fields;

        query += ` limit ${cmdObj.limit}`;
        let cursor = client.query(new Cursor(query));
        try {
            for (; ;) {
                let rows = await cursor.read(10);
                if (rows.length === 0) {
                    break;
                }
                utils.displayCursorResultSet(fields, rows);
            }
        } finally {
            await cursor.close();
        }
    });

    program.command('compareLabs <a> <b>')
    .option('-l|--limit <rows>', 'number rows', utils.myParseInt, 1000)
    .option('-p|--patients <rows>', 'number patients', utils.myParseInt, 10)
    .option('-x|--patient <entity_id>', 'patient', utils.myParseInt, -1)
    .action(async function (schema1, schema2, cmdObj) {
        let fieldQuery = `SELECT ${LAB_COLUMNS.join(',')} from ${schema1}.labs limit 0`;
        let fields = (await client.query(fieldQuery)).fields;

        let maxEntityId = utils.scalarResult(await client.query(`select max(entity_id) from ${schema1}.cohort`));

        let query = `SELECT ${LAB_COLUMNS.join(',')} from SCHEMA.labs where entity_id in (IDS) order by entity_id, visit_id, component_id limit ${cmdObj.limit}`;

        let patientsAtOnce, start, end;

        if (cmdObj.patient !== -1) {
            start = cmdObj.patient;
            end = start;
            patientsAtOnce = 1;
        } else {
            start = 0;
            end = Math.min(cmdObj.patients, parseInt(maxEntityId));
            patientsAtOnce = 1;
        }

        for (let e = start; e <= end; e += patientsAtOnce) {
            let ids = [...Array(patientsAtOnce).keys()].map(x => x + e).join(',');
            let q1 = query.replace(/SCHEMA/g, schema1).replace(/IDS/, ids);
            let q2 = query.replace(/SCHEMA/g, schema2).replace(/IDS/, ids);
            let res1 = await client.query({ text: q1, rowMode: 'array' });
            let res2 = await client.query({ text: q2, rowMode: 'array' });

            if (res1.rowCount || res2.rowCount) {
                console.log(`Check from ${e} to ${e + patientsAtOnce - 1}`);
                for (let i = 0; i < Math.min(res1.rowCount, res2.rowCount); ++i) {
                    let r1 = res1.rows[i];
                    let r2 = res2.rows[i];

                    if (JSON.stringify(r1) !== JSON.stringify(r2)) {
                        utils.displayCursorResultSet(fields, [r1]);
                        utils.displayCursorResultSet(fields, [r2]);

                        if (start === end) {
                            utils.displayCursorResultSet(fields, res1.rows);
                            utils.displayCursorResultSet(fields, res2.rows);
                        }

                        return;
                    }
                    if (res1.rowCount !== res2.rowCount) {
                        console.log(`Row count difference for at ${e}`);
                        return;
                    }
                }
            }
        }

    });

program.command('compareMed <a> <b>')
    .option('-l|--limit <rows>', 'number rows', utils.myParseInt, 1000)
    .option('-p|--patients <rows>', 'number patients', utils.myParseInt, 10)
    .option('-x|--patient <entity_id>', 'patient', utils.myParseInt, -1)
    .action(async function (schema1, schema2, cmdObj) {
        let fieldQuery = `SELECT ${MED_COLUMNS.join(',')} from ${schema1}.medications limit 0`;
        let fields = (await client.query(fieldQuery)).fields;

        let maxEntityId = utils.scalarResult(await client.query(`select max(entity_id) from ${schema1}.cohort`));

        let query = `SELECT ${MED_COLUMNS.join(',')} from SCHEMA.medications where entity_id in (IDS) order by entity_id, visit_id, enc_type, medication limit ${cmdObj.limit}`;

        let patientsAtOnce, start, end;

        if (cmdObj.patient !== -1) {
            start = cmdObj.patient;
            end = start;
            patientsAtOnce = 1;
        } else {
            start = 0;
            end = Math.min(cmdObj.patients, parseInt(maxEntityId));
            patientsAtOnce = 1;
        }

        let ec = MED_COLUMNS.indexOf('enc_type');

        for (let e = start; e <= end; e += patientsAtOnce) {
            let ids = [...Array(patientsAtOnce).keys()].map(x => x + e).join(',');
            let q1 = query.replace(/SCHEMA/g, schema1).replace(/IDS/, ids);
            let q2 = query.replace(/SCHEMA/g, schema2).replace(/IDS/, ids);
            let res1 = await client.query({ text: q1, rowMode: 'array' });
            let res2 = await client.query({ text: q2, rowMode: 'array' });

            if (res1.rowCount || res2.rowCount) {
                console.log(`Check from ${e} to ${e + patientsAtOnce - 1}`);
                for (let i = 0; i < Math.min(res1.rowCount, res2.rowCount); ++i) {
                    let r1 = res1.rows[i];
                    let r2 = res2.rows[i];

                    r1[ec] = r2[ec] = null;
                    if (JSON.stringify(r1) !== JSON.stringify(r2)) {
                        utils.displayCursorResultSet(fields, [r1]);
                        utils.displayCursorResultSet(fields, [r2]);

                        if (start === end) {
                            utils.displayCursorResultSet(fields, res1.rows);
                            utils.displayCursorResultSet(fields, res2.rows);
                        }

                        return;
                    }
                    if (res1.rowCount !== res2.rowCount) {
                        console.log(`Row count difference for at ${e}`);
                        return;
                    }
                }
            }
        }

    });

async function main() {
    try {
        let args = process.argv;
        if (process.argv.length === 2) {
            let cmd;
            cmd = 'medQuery -s mlg_ml_mednew1_100';
            cmd = 'compareMed mlg_ml_medorig_100 mlg_ml_mednew1_100 -x 12';
            cmd = 'compareLabs mlg_ml_100 mlg_ml-1000_new_labs_1000';
            args = [...process.argv, ...cmd.split(' ')];
        }

        await client.connect();

        await program.parseAsync(args);
    } catch (err) {
        console.log(err);
        console.log(err.message ?? err);
    } finally {
        client.end();
    }
    process.exit(0);
}

main();


