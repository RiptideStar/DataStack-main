'use strict';

const { table, getBorderCharacters } = require('table');

function myParseInt(v, p) {
    return parseInt(v);
}

function myParseString(v, p) {
    return v;
}


function prepareData(data, columns, options) {
    if (data.length === 0) {
        return [];
    } else if (Array.isArray(data[0])) {
        let formatters = [ ] ;
        for (let i = 0; i < columns.length; ++i) {
            let f = options?.formatters?.[columns[i]] ;
            if (f) {
                formatters.unshift({idx: i, formatter: f, column: columns[i]}) ;
            }
        }

        if (formatters.length) {
            let tableData = data.map(d => {
                for (let f of formatters) {
                    d[f.idx] = f.formatter(d[f.idx]);
                }
            }) ;
        }
        return data;
    } else {
        let tableData = data.map(d => columns.map(c => {
            let f = options?.formatters?.[c];
            return f ? f(d[c]) : d[c];
        }));
        return tableData;
    }
}

function prepareConfig(columns, options) {
    let opts = {
        border: getBorderCharacters(`void`),
        columnDefault: {
            paddingLeft: 0,
            paddingRight: 4
        },
        drawHorizontalLine: () => {
            return false
        }
    };

    return opts;
}

function displayTable(data, columns, options = {}) {
    let tableData = prepareData(data, columns, options);
    tableData.unshift(columns);

    let config = prepareConfig(columns, options);

    let s = table(tableData, config);
    console.log(s);
}

const PG_DATATYPES = {
    timestamp: 1114
}

const formattersByType = {
    [PG_DATATYPES.timestamp]: v => { try { return v?.toISOString(); } catch { return v;} }
}

function displayResultSet(res) {
    displayCursorResultSet(res.fields, res.rows);
}


function displayCursorResultSet(fields, rows) {
    let columns = fields.map(f => f.name);
    let formatters = Object.fromEntries(fields.map(e => [e.name, formattersByType[e.dataTypeID]]));
    displayTable(rows, columns, { formatters });
}

function scalarResult(result) {
    return Object.values(result.rows[0])[0];
}

module.exports = {
    myParseInt,
    myParseString,

    PG_DATATYPES,
    scalarResult,

    displayTable,
    displayResultSet,
    displayCursorResultSet
};

