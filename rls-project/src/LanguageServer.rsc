module LanguageServer

import IO;
import String;
import Map;
import util::Webserver;

// Address of the server
loc addr = |http://localhost:12366|;

alias Position = tuple[int,int];
alias Range = tuple[Position, Position];
alias LocationInDoc = tuple[loc, Range];

alias Json = map[str, value];
alias Header = map[str, str];

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

loc startServer() {

  try {
    serve(addr, getResponse);
    return addr;
  }
  catch IO(e):
    println("IO error: <e>");
  catch value e:
    println("Unknown error: <e>");

}

void stopServer() = shutdown(addr);

Json message(str id, str method) = ("jsonrpc" : "2.0",
                                          "id": id,
                                          "method" : method);

Json message(int id, str method) = message("<id>", method);

Json resultResponse(int id, Json result) = message(id) + ("result": result);
Json errorResponse(int id, Json error) = message(id) + ("error": error);

Json notification(int id, str method, Json params) = message(id, method) + ("params": params);

Header craftHeader() = (
  //"Content-Length" : l,
  "Content-Type" : "application/vscode-jsonrpc; charset=utf-8");

Response getResponse(Request r) {
  Response resp = jsonResponse(ok(), (), message(1));
  println("Request arrived");
  return resp;
}

//void main(list[str] args) {
//  println("Starting language server");
//  startServer();
//}