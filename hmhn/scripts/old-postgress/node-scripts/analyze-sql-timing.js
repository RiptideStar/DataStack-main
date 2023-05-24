'use strict' ;

const utils = require('./utils');
const { Command, CommanderError, storeOptionsAsProperties, exitOverride, InvalidOptionArgumentError } = require('commander');
const { count } = require('console');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const program = new Command();



function pathSortInfo(fn) {
    let m = fn.match(/^(.*)-([0-9]+)[.]/) ;
    if (m) {
        return { file: m[1], num: Number(m[2]) } ;
    } else {
        return { file: fn, num : 0 } ;
    }
}


program.command('sqltimings')
    .arguments('<paths...>', 'sql log files')
    .option('-t|--threshold <num>', 'show times till <num>%', utils.myParseInt, 80)
    .action(async function (paths, cmdObj) {
        let threshold = cmdObj.threshold;

        paths.sort((a,b) => {
            let fa = pathSortInfo(a) ;
            let fb = pathSortInfo(b) ;
            let x = fa.file.localeCompare(fb.file) ;
            if (x !== 0) {
                return x;
            } else {
                return fa.num - fb.num ;
            }
        }) ;

        for (let f of paths) {
            const fileStream = fs.createReadStream(f);
            const rl = readline.createInterface({
                input: fileStream,
                crlfDelay: Infinity
            });

            let currentAction = null;
            let fileTimeSec = 0;
            let fileSummaryTime = 0;
            let sections = {};
            let data = {};
            let currentFile = null;
            // console.log(`---- ${f} ----`);
            for await (const line of rl) {
                let start = line.match(/---- Start (.*) ----/) ;
                let timing = line.match(/^Time: ([0-9.]+) ms/);
                let ranIn = line.match(/---- Ran (.*) in (\d+) seconds/);
                if (start) {
                    let sm =  start[1].match(/([a-zA-Z0-9_-]+)/) ;
                    currentFile = sm[1];
                } else if (timing) {
                    let tm = Math.round(Number(timing[1]) / 1000);
                    fileTimeSec += tm;
                    data[currentAction] = { time: tm, action: currentAction, file: currentFile };
                    currentAction = null;
                } else if (ranIn) {
                    fileSummaryTime += Math.round(Number(ranIn[2])) ;
                    sections[currentFile] = { file: currentFile, time: Math.round(Number(ranIn[2])) } ;
                    currentFile = null;
                } else {
                    currentAction = line;
                }
            }
            
            
            let allSections = Object.values(sections) ;
            allSections.sort((a, b) => b.time - a.time);
            for (let sec of allSections) {
                sec.displayMe = sec.time > 10;
            }
            allSections = allSections.filter(i => i.displayMe );

            let dataRows = Object.values(data);
            let cumulativeTime = 0;
            dataRows.sort((a, b) => b.time - a.time);
            for (let x of dataRows) {
                x.percent = Math.round(x.time * 100 / fileTimeSec);
                x.displayMe = threshold === 100 ||  x.time > 10 && x.percent > 1 && cumulativeTime * 100 / fileTimeSec < threshold ;
                cumulativeTime += x.time;
            }
            dataRows = dataRows.filter(i => i.displayMe );
  

            console.log(`---- ${f} ran in time ${fileSummaryTime} sec with ${cumulativeTime} sec cumulative sum ----`);
            if (currentFile) {
                console.log(`**** incomplete data **** ${currentFile} is still running`);
            }
            utils.displayTable(allSections, ['file', 'time']);
            utils.displayTable(dataRows, ['action', 'time', 'percent', 'file']);
            // console.log(sections) ;
        }
    });


async function main() {
    try {
        await program.parseAsync(process.argv);
    } catch (err) {
        console.log(err);
        console.log(err.message ?? err);
    }
    process.exit(0);
}

main();

