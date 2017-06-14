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
  println("Registered language \"" + language + "\" on endpoint");
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

Response getResponse(Request r) {

  items = r.content(#map[str,value]);

  // Use the path as language identifier
  languageName = substring(r.path, 1);
  println("Language: " + languageName);

  s = split("/", items["method"]);
  method = size(s) == 2 ? s[1] : s[0];

  //LSPRequest lspRequest = make(#LSPRequest, method, ());
  //LSPResponse = languages[languageName](lspRequest);

  // todo: data structure to map[str, value]
  // JsonValueWriter in webserver handles conversion map -> json

  Response resp = jsonResponse(ok(), (), ());
  return resp;
}

//void main(list[str] args) {
//  println("Starting language server");
//  startServer();
//}