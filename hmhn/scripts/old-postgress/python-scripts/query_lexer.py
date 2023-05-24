from enum import Enum

class UserException(Exception):
    pass

class Token(Enum):
  EOF = 0
  STRING = 1
  COMMENT = 2
  WHITE_SPACE = 3
  NEWLINE = 4
  TOKEN = 5
  DIRECTIVE = 6
  SEMI = 7

class QueryLexer:
  def __init__(self, source):
    self.source = source
    self.current_position = 0
    self.at_beginning_of_line = True

     # return the token
  # the tokens will just be
  # directive
  # sql expression
  def next(self):
    if self.looking_at_eof():
      return self.parse_eof()
    elif self.looking_at_newline():
      return self.parse_newline()
    elif self.looking_at_whitespace():
      return self.parse_white_space()
    elif self.looking_at_multi_line_string():
      return self.parse_multi_line_string()
    elif self.looking_at_string_delimiter():
      return self.parse_string()
    elif self.looking_at_comment_to_eol():
      return self.parse_comment_to_eol()
    elif self.looking_at_directive():
      return self.parse_directive()
    elif self.looking_at_semi():
      return self.parse_semi()
    elif self.looking_at_token():
      return self.parse_token()
    else:
      raise UserException(f'bad lexer state at {self.current_position}')

  def peek(self):
    if self.looking_at_eof():
      return None
    else:
      return self.source[self.current_position]

  def advance(self):
    if self.current_position == len(self.source):
      return None
    else:
      self.current_position += 1
      return self.source[self.current_position-1]
    
  def token(self, token_type, start):
    return (token_type, self.source[start:self.current_position])
  
  def looking_at(self, txt):
    if self.looking_at_eof():
      return False
    return self.source[self.current_position:self.current_position+len(txt)] == txt

  def looking_at_eof(self):
    return self.current_position == len(self.source)
  
  def parse_eof(self):
    return (Token.EOF, "")
    
  def looking_at_string_delimiter(self):
    if self.looking_at_eof():
      return False
    next = self.peek()
    return next == '"' or next == '`' or next == "'"
  
  def parse_string(self):
    self.at_beginning_of_line = False
    start = self.current_position
    delimiter = self.advance()
    while not self.looking_at_eof() and not self.looking_at_newline() and not self.looking_at(delimiter):
      if self.looking_at('\\'):
        self.advance()
      self.advance()

    if self.looking_at(delimiter):
      self.advance()
      return self.token(Token.STRING, start)
    else:
      raise UserException('unterminated string')
   
  def looking_at_newline(self):
    if self.looking_at_eof():
      return False
    next = self.peek()
    return next == '\n'
  
  def parse_newline(self):
    start = self.current_position
    self.advance()
    self.at_beginning_of_line = True
    return self.token(Token.NEWLINE, start)
  
  def looking_at_comment_to_eol(self):
    if self.looking_at_eof():
      return False
    return self.looking_at('--')

  def parse_comment_to_eol(self):
    start = self.current_position
    while not self.looking_at_eof() and not self.looking_at_newline():
      self.advance()
    return self.token(Token.COMMENT, start)
  
  def looking_at_directive(self):
    if self.looking_at_eof():
      return False
    return self.looking_at('\\') and self.at_beginning_of_line
  
  def parse_directive(self):
    start = self.current_position
    while not self.looking_at_eof() and not self.looking_at_newline():
      self.advance()
    return self.token(Token.DIRECTIVE, start)
  
  def looking_at_semi(self):
    return self.looking_at(';')
  
  def parse_semi(self):
    self.at_beginning_of_line = False
    start = self.current_position
    self.advance()
    return self.token(Token.SEMI, start)
  
  
  def looking_at_multi_line_string(self):
    return self.looking_at('"""')
  
  def parse_multi_line_string(self):
    self.at_beginning_of_line = False
    start = self.current_position
    self.advance()
    self.advance()
    self.advance()
    while not self.looking_at_eof() and not self.looking_at_multi_line_string():
      self.advance()
    
    if self.looking_at_multi_line_string():
      self.advance()
      self.advance()
      self.advance()
      return self.token(Token.STRING, start)
    else:
      raise UserException('unterminated string')
    

  def looking_at_whitespace(self):
    if self.looking_at_eof():
      return False
    next = self.peek()
    return next.isspace()
  
  def parse_white_space(self):
    start = self.current_position
    while not self.looking_at_eof() and self.looking_at_whitespace():
      self.advance()
    return self.token(Token.WHITE_SPACE, start) 
  
  def looking_at_token(self):
    return \
        not self.looking_at_eof() \
        and not self.looking_at_whitespace()  \
        and not self.looking_at_multi_line_string()  \
        and not self.looking_at_string_delimiter()  \
        and not self.looking_at_semi()  \
        and not self.looking_at_comment_to_eol()  \
        and not self.looking_at_newline() 


  def parse_token(self):
    self.at_beginning_of_line = False
    start = self.current_position
    self.advance()
    while self.looking_at_token():
      self.advance()
    return self.token(Token.TOKEN, start) 
  

    

  



  

  