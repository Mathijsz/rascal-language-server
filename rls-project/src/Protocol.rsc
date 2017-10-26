module Protocol

import util::Maybe;

data LSPRequest (str namespace = "")
  = initialize(int processId = -1, str rootPath = "", Trace trace = off())
  | didOpen(TextDocument textDocument)
  | didClose(TextDocument textDocument)
  | hover(TextDocument textDocument)
  | shutdown()
  | cancelRequest(int id)
  | invalid(str method)
  ;

data LSPResponse
  = initializeResult(ServerCapabilities capabilities = capabilities())
  | hoverResult(str contents, loc range)
  | none()
  ;

data ClientCapabilities
  = clientCapabilities()
  ;

data ServerCapabilities
  = capabilities(int textDocumentSync = 2, bool hoverProvider = true)
  ;

data TextDocument
  = textDocument(loc uri, str languageId, int version, str text)
  | textDocument(loc uri)
  ;

data Trace
  = on()
  | off()
  | messages()
  | verbose()
  ;

data Diagnostic
  = diagnostic(loc range, str message, int severity = 1, Maybe[value] code = nothing(), str source = "")
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