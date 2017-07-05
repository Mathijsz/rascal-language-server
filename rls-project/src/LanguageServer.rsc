module LanguageServer

import IO;
import String;
import Map;
import List;
import util::Webserver;
import lang::json::IO;

import Type;
import Node;

import Protocol;

// Address of the server
loc addr = |http://10.0.0.33:12366|;

alias Handle = LSPResponse (LSPRequest);

map[str name, Handle h] languages = ();

void register(str language, Handle h) {
  languages[language] = h;
  println("Registered language \"" + language + "\"");
}

void deregister(str language) {
  delete(languages, language);
  println("Deregistered language \"" + language + "\"");
}

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

LSPRequest mapToRequest(type[&T] t, str method, node params) {
  map[str,value] paramMap = getKeywordParameters(params);
  for (key <- params, typeOf(key) is \node) {
    switch (key) {
      case "capabilities": {
        paramMap[key] = clientCapabilities(paramMap[key].workspace, paramMap[key].textDocument);
      }
    }
  }
  return make(t, method, [], paramMap);
}

map[str,value] toMap(node n) {
  if (n is none) return ();
  // TODO: should probably get all parameters instead of just kwargs
  args = getKeywordParameters(n);
  for (key <- args, typeOf(args[key]) is adt) {
    args[key] = toMap(args[key]);
  }
  return args;
}

map[str,value] responseToMap(LSPResponse lspResp) = ("result" : toMap(lspResp));

Response getResponse(Request r) {
  items = typeCast(#map[str,value], r.content(#map[str,value]));
  languageName = substring(r.path, 1);
  id = typeCast(#int, items["id"]?(-1));

  if (languageName notin languages) {
    println("Client indicated non-registered language \"" + languageName + "\"");
    languageName = "rascal";
  }
  method = typeCast(#str, items["method"]);
  s = split("/", method);
  methodName = size(s) == 2 ? s[1] : s[0];

  LSPRequest lspReq = mapToRequest(#LSPRequest, methodName, typeCast(#node, items["params"]?""() ));
  lspReq.namespace = size(s) == 2 ? s[0] : "";
  LSPResponse lspResp = languages[languageName](lspReq);

  return jsonResponse(ok(), (), ("id": id) + responseToMap(lspResp));
}

//void main(list[str] args) {
//  println("Starting language server");
//  startServer();
//}