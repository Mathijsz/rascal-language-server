module Protocol

import util::Maybe;

data LSPRequest
  = initialize(int pid = -1, str rootUri = "", Trace trace = off())
  | hover(str textDocument, Position position)
  | shutdown()
  ;

data LSPResponse
  = hover(str contents, Range range)
  ;

data Trace
  = on()
  | off()
  | messages()
  | verbose()
  ;

data Diagnostic
  = diagnostic(Range range, str message, int severity = 1, Maybe[value] code = nothing(), str source = "")
  ;

data Position
  = position(int line, int character)
  ;

data Range
  = range(Position start_, Position end_)
  ;

data Location
  = location(loc uri, Range range)
  ;

map[str, int] errorCodes = (
  "ParseError" :            -32700,
  "InvalidRequest" :        -32600,
  "MethodNotFound" :        -32601,
  "InvalidParams" :         -32602,
  "InternalError" :         -32603,
  "serverErrorStart" :      -32099,
  "serverErrorEnd" :        -32000,
  "ServerNotInitialized" :  -32002,
  "UnknownErrorCode" :      -32001,
  "RequestCancelled" :      -32800
);

map[str, int] diagSeverity = (
  "Error" :       1,
  "Warning":      2,
  "Information":  3,
  "Hint":         4
);