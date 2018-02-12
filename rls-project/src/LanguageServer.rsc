module LanguageServer

import IO;
import String;
import Map;
import Set;
import List;
import util::Webserver;
import lang::json::IO;

import Type;
import Node;

import Protocol;

import DefaultKWs;

// Address of the server
loc addr = |http://127.0.0.1:12366|;

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

  for (key <- paramMap) {
    ptype = typeOf(paramMap[key]);

    if (ptype is \node) {
      currentNodeParams = getKeywordParameters(typeCast(#node, paramMap[key]));
      switch (key) {
        case "capabilities": {
          paramMap[key] = clientCapabilities();
        }
        case "textDocument": {
          currentNodeParams["uri"] = toLocation(typeCast(#str, currentNodeParams["uri"]));

          if ("position" in paramMap)
            currentNodeParams["uri"] = toLocation(currentNodeParams["uri"], readPosition(typeCast(#node, paramMap["position"])));

          paramMap[key] = make(#TextDocument, key, currentNodeParams);
        }
      }
    }
    if (ptype is \list) {
      plist = typeCast(#list[node], paramMap[key]);
      switch (key) {
        case "contentChanges": {
          println("got contentChanges");
          list[DocumentChange] changes = [];
          for (change <- plist) {
            changeParams = getKeywordParameters(change);
            if ("range" in changeParams && "rangeLength" in changeParams) {
              length = typeCast(#int, changeParams["rangeLength"]);
              changes += contentChanges(typeCast(#str, changeParams["text"]),
                toLocation(readRange(changeParams["range"]), length), length);
              continue;
            }
            changes += contentChanges(typeCast(#str, changeParams["text"]));
          }
          paramMap[key] = changes;
        }
      }
    }
  }
  return make(t, method, paramMap);
}

alias Position = tuple[int line, int character];
alias Range = tuple[Position begin, Position end];

Position readPosition(node pos) {
  pm = getKeywordParameters(typeCast(#node, pos));
  return <typeCast(#int, pm["line"]), typeCast(#int, pm["character"])>;
}

Range readRange(node range) {
  rm = getKeywordParameters(typeCast(#node, range));
  return <readPosition(rm["start"]), readPosition(rm["end"])>;
}

public loc toLocation(loc s, Position pos) {
  if (/<scheme:.*>\:\/\/<rest:.*>/ := s.uri) {
    return |<scheme>://<rest>|(positionToOffset(s, pos.line, pos.character), 0, pos, pos);
  }
  return |cwd:///<s.uri>|(positionToOffset(s, pos.line, pos.character), 0, pos, pos);
}

public loc toLocation(loc s, Range range, int rangeLength) {
  if (/<scheme:.*>\:\/\/<rest:.*>/ := s.uri) {
    return |<scheme>://<rest>|(positionToOffset(s, range.begin.line, range.begin.character), rangeLength, range.begin, range.end);
  }
  return |cwd:///<s.uri>|(positionToOffset(s, range.begin.line, range.begin.character), rangeLength, range.begin, range.end);
}

int positionToOffset(loc document, int lineNr, int character)
   = character + sum([0]+[ size(line) + 1 | line <- take(lineNr, readFileLines(document)) ]);

&T make(type[&T] t, str constructor, map[str,value] arguments) {
  orderedArguments = [ arguments[name] | name <- findParameters(t, \adt(t.symbol.name, []), constructor), name in arguments ];
  return make(t, constructor, orderedArguments, arguments);
}

bool constructorExistsForType(type[&T] t, str constrName)
  = /constr:\cons(label(constrName,_), _, _, _) := t.definitions;

map[str,value] locToRange(loc l) = ("start":  ("line": l.begin.line, "character": l.begin.column),
                                    "end":    ("line": l.end.line,   "character": l.end.column ));

list[str] findParameters(type[&T] t, Symbol s, str constrName) {
  defs = t.definitions[s].alternatives;

  str fixName(str param) = (startsWith(param, "_") ? substring(param, 1) : param);

  syms = [];
  for (/constr:\cons(label(constrName, s), _, _, _) := defs, size(constr.symbols) > size(syms)) {
    syms = constr.symbols;
  }

  return [ fixName(param.name) | param <- syms ];
}

value toMap(node n) {
  if (n is none) return ();

  parameters = findParameters(#LSPResponse, typeOf(n), getName(n));
  n = setKeywordParameters(n, getDefaultKeywordParams(getName(n), parameters) - getKeywordParameters(n));

  args = getChildren(n);
  kwargs = getKeywordParameters(n);

  if (size(args) > 0)
    kwargs += ( p:val | <p,val> <- zip(take(size(args), parameters), args));

  for (key <- kwargs) {
    keyType = typeOf(kwargs[key]);

    if (key == "locations")
      return [ ("uri": l.uri, "range": locToRange(l)) | l <- typeCast(#list[loc], kwargs[key]) ];
    else if (keyType is \list)
      kwargs[key] = [ toMap(k) | k <- typeCast(#list[node], kwargs[key]) ];
    if (keyType is \adt)
      kwargs[key] = toMap(kwargs[key]);
    if (keyType is \loc)
      kwargs[key] = key == "range" ? locToRange(kwargs[key]) : l.uri;

  }
  return kwargs;
}

Response errorResponse(int id, str errorType, str message) = errorResponse(id, errorType, message, 0);
Response errorResponse(int id, str errorType, str message, value _data) = response(id, "error", errorMsg(message, _data, errorCodes[errorType]?"UnknownErrorCode"));

Response okResponse(int id, node n) = response(id, "result", n);

Response response(int id, str respType, node n)
  = jsonResponse(ok(), (),
      (
        "jsonrpc": "2.0",
        "id": id,
        respType: toMap(n)
      )
      - (hasNewMethod(n) ? ("id" : -1) : ())
      + (hasNewMethod(n) ? ("method" : n.methodOverride) : ())
    );

bool hasNewMethod(node n) = n has methodOverride && n.methodOverride != "";

Response getResponse(Request r) {
  items = typeCast(#map[str,value], r.content(#map[str,value]));
  languageName = substring(r.path, 1);
  id = typeCast(#int, items["id"]?(-1));

  if (languageName notin languages) {
    println("Client indicated non-registered language \"" + languageName + "\"");
    languageName = "rascal";
    return errorResponse(id, "InvalidRequest", "Unknown language");
  }

  if ("method" notin items && "error" in items) {
    errors = typeCast(#node, items["error"]);
    errorName = getOneFrom(invert(errorCodes)[errors.code]);
    println("Client indicated error <errorName>: <errors.message>");
    return okResponse(id, none());
  }

  method = typeCast(#str, items["method"]);
  s = split("/", method);
  methodName = size(s) == 2 ? s[1] : s[0];

  LSPRequest lspReq = mapToRequest(#LSPRequest, methodName, typeCast(#node, items["params"]?""() ));
  lspReq.namespace = size(s) == 2 ? s[0] : "";
  lspReq.language = languageName;
  lspReq.reqId = id;
  LSPResponse lspResp = languages[languageName](lspReq);

  if (lspResp.methodOverride != "")
    return response(id, "params", lspResp);

  return okResponse(id, lspResp);
}
