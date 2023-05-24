import query_lexer
import re
from enum import Enum

class Action(Enum):
  EOF = 0
  DIRECTIVE = 1
  SQL = 2

class QueryParser:
    def __init__(self, source, variables):
        self.source = source
        self.variables = variables
        self.lexer = query_lexer.QueryLexer(source)
        self.next_token = None

    def peek(self):
        if self.next_token == None:
            self.next_token = self.lexer.next()
        return self.next_token

    def advance(self):
        if self.next_token == None:
            return self.lexer.advance()
        else:
            tmp = self.next_token
            self.next_token = None
            return tmp
 
    def next(self):
        while True:
            (next_token, next_value) = self.peek()
            if next_token == query_lexer.Token.EOF:
                return (Action.EOF, '')
            elif next_token == query_lexer.Token.STRING \
                 or next_token == query_lexer.Token.TOKEN:
                return self.parse_sql()
            elif next_token == query_lexer.Token.DIRECTIVE:
                return self.parse_directive()
            elif next_token ==  query_lexer.Token.WHITE_SPACE \
                 or next_token == query_lexer.Token.COMMENT \
                 or next_token == query_lexer.Token.SEMI \
                 or next_token == query_lexer.Token.NEWLINE:
                self.advance()
            else:
                raise Exception(f'unexpected token {next_token}')
            
    def parse_directive(self):
        (tok, val) = self.advance()
        val = self.replace_variables(val)
        return (Action.DIRECTIVE, val)
    
    def replace_variable(self, match_obj):
        var = match_obj.group(1)
        if var in self.variables:
            return self.variables[var]
        elif match_obj.group(2) != None:
            return match_obj.group(2)
        else:
            raise Exception(f'undefined variable "{var}"')
    
    def replace_variables(self, data):
        return re.sub(r"{(\S+?)(?:[:](.*?))?}", lambda x: self.replace_variable(x), data)
    
    def parse_sql(self):
        tokens = []
        while True:
            (next_token, next_value) = self.peek()
            if next_token == query_lexer.Token.EOF:
                self.advance()
                break
            elif next_token == query_lexer.Token.SEMI:
                self.advance()
                break
            elif next_token == query_lexer.Token.STRING \
                 or next_token == query_lexer.Token.TOKEN \
                 or next_token ==  query_lexer.Token.WHITE_SPACE \
                 or next_token == query_lexer.Token.NEWLINE:
                tokens.append(next_value)
                self.advance()
            elif next_token == query_lexer.Token.DIRECTIVE:
                break
            elif next_token == query_lexer.Token.COMMENT:
                self.advance()
            else:
                raise Exception(f'unexpected token ${next_token}')
        sql = ''.join(tokens)
        return (Action.SQL, self.replace_variables(sql))
