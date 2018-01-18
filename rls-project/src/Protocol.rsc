module Protocol

import util::Maybe;

data LSPRequest (str language = "", str namespace = "", int reqId = -1)
  = initialize(int processId = -1, str rootPath = "", Trace trace = off())
  | initialized()
  | didOpen(TextDocument textDocument)
  | didClose(TextDocument textDocument)
  | hover(TextDocument textDocument)
  | definition(TextDocument textDocument)
  | shutdown()
  | exit()
  | cancelRequest(int id)
  | invalid(str method)
  ;

data LSPResponse
  = initializeResult(ServerCapabilities capabilities = capabilities())
  | hoverResult(str contents, loc range)
  | hoverResult(str contents)
  | locationResult(str uri, loc range)
  | none()
  ;

data ClientCapabilities
  = clientCapabilities()
  ;

data ServerCapabilities
  = capabilities(int textDocumentSync = textDocumentSyncKind["Full"],
      bool hoverProvider = false,
      bool definitionProvider = true
    )
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

data ResponseError
  = errorMsg(str message, value _data, int code)
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

map[str, int] textDocumentSyncKind = (
  "None":         0,
  "Full":         1,
  "Incremental":  2
);
