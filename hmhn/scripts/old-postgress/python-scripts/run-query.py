# pip install google-cloud-bigquery pandas db-dtypes jinja2 tabulate
import re
import os
import sys
import argparse
import google.api_core.exceptions;

from BigQueryEvaluator import BigQueryEvaluator, UserException
import query_parser

default_key_file=os.path.expanduser("~/.gcloud/sa_key.json")
default_project='hmh-carenostics-dev'
default_hmhn='hmh-datalake-dev.poc_dev'
parser = argparse.ArgumentParser(description='Run a bigquery script')
parser.add_argument('script', type=argparse.FileType('r'), help="use '-' to read from stdin", metavar='<scriptFile>')
parser.add_argument('--key-file', help=f'path to key.json file. ({default_key_file}) ', metavar='<keyFile>', default=default_key_file)
parser.add_argument('--d', help='define substitution.  --d x=y', action='append', metavar='<var=val>)', default=[])
parser.add_argument('--project', help=f'project. ({default_project}) ', metavar='<project>', default=default_project)
parser.add_argument('--dataset', help=f'default dataset.', metavar='<dataset>', default=None)
parser.add_argument('--hmhn', help=f'short for --d hmhn=<>.  defaults to {default_hmhn}', default=default_hmhn)
# hmh-datalake-prod-c5b4.CLARITY
parser.add_argument('--debug', help=f'debug mode. show extended error information', action=argparse.BooleanOptionalAction, default=False)
parser.add_argument('--lexer', help=f'test lexer', action=argparse.BooleanOptionalAction, default=False)


gettrace = getattr(sys, 'gettrace', None)
if len(sys.argv) != 1 or  gettrace == None or not gettrace():
    args = parser.parse_args()
else:
    # running in the debugger
    cmd = '--dataset mlg ../../carenostics_ml_bigquery/base_table_insertion.sql'
    cmd = '--dataset mlg ../../carenostics_ml_bigquery/update-patient-mapping.sql'
    cmd = '--dataset mlg ../../../xx.sql'
    cmd = '--lexer test/parse-test.sql'
    args = parser.parse_args(cmd.split(' ')) 


variables = { }

variables['hmhn'] = args.hmhn
if args.dataset != None:
    variables['dataset'] = args.dataset
variables['project'] = args.project
for var in args.d:
    p = re.split('=', var, 2)
    if len(p) != 2:
        print(f'invalid variable definition: {var}')
        os.exit()
    variables[p[0]] = p[1]

if args.lexer:
    data = args.script.read()
    parser = query_parser.QueryParser(data, variables)
    while True:
        token,value = parser.next()
        if token == query_parser.Action.EOF:
            break
        value = value.replace('\n', '\\n') 
        print(f'{token.name}: {value}.')
    sys.exit()


bqe = BigQueryEvaluator(args.key_file, args.project, args.dataset, variables)


if args.script.name != '<stdin>':
  scriptDir = os.path.dirname(args.script.name)
else:
  scriptDir = os.getcwd()

if args.debug:
    bqe.execute(args.script.read(), scriptDir)
else:
    try:
        bqe.execute(args.script.read(), scriptDir)
    except UserException as e:
        print(e)
    except google.api_core.exceptions.BadRequest as e:
        print(f'GoogleException: {e.errors[0]["message"]}')
    except Exception as e:
        print(f'Error: {e}')
