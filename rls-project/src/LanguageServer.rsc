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

  if (!constructorExistsForType(t, method)) {
    println("method \'<method>\' invalid or not (yet) supported");
    return make(t, "invalid", [method]);
  }

  map[str,value] paramMap = getKeywordParameters(params);
  for (key <- paramMap, typeOf(paramMap[key]) is \node) {
    currentNodeParams = getKeywordParameters(typeCast(#node, paramMap[key]));
    switch (key) {
      case "capabilities": {
        paramMap[key] = clientCapabilities();
      }
      case "textDocument": {
        location = |tmp:///|;
        location.uri = typeCast(#str, currentNodeParams["uri"]);
        currentNodeParams["uri"] = location;
        paramMap[key] = make(#TextDocumentItem, key, currentNodeParams);
      }
    }
  }
  return make(t, method, paramMap);
}

&T make(type[&T] t, str constructor, map[str,value] arguments) {
  orderedArguments = [ arguments[name] | name <- findParameters(t, \adt(t.symbol.name, []), constructor), name in arguments ];
  return make(t, constructor, orderedArguments, arguments);
}

bool constructorExistsForType(type[&T] t, str constrName)
  = /constr:\cons(label(constrName,_), _, _, _) := t.definitions;

map[str,value] locToRange(loc l) = ("start":  ("line": l.begin.line, "character": l.begin.column),
                                    "end":    ("line": l.end.line,   "character": l.end.column ));

//map[str, type[&T]] reifType = (
//  "LSPResponse" : #LSPResponse,
//  "LSPRequest" : #LSPRequest
//);

list[str] findParameters(type[&T] t, Symbol s, str constrName) {
  defs = t.definitions[s].alternatives;

  str fixName(str param) = (startsWith(param, "_") ? substring(param, 1) : param);

  syms = [];
  for (/constr:\cons(label(constrName, s), _, _, _) := defs, size(constr.symbols) > size(syms)) {
    syms = constr.symbols;
  }

  return [ fixName(param.name) | param <- syms ];
}

map[str,value] toMap(node n) {
  if (n is none) return ();

  args = getChildren(n);
  kwargs = getKeywordParameters(n);

  if (size(args) > 0)
    kwargs += ( p:val | <p,val> <- zip(findParameters(#LSPResponse, typeOf(n), getName(n)), args));

  for (key <- kwargs) {
    keyType = typeOf(kwargs[key]);

    if (keyType is \adt)
      kwargs[key] = toMap(kwargs[key]);
    if (keyType is \loc)
      kwargs[key] = key == "range" ? locToRange(kwargs[key]) : l.uri;

  }
  return kwargs;
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
  return jsonResponse(ok(), (), ("jsonrpc": "2.0", "id": id) + responseToMap(lspResp));
}

//void main(list[str] args) {
//  println("Starting language server");
//  startServer();
//}