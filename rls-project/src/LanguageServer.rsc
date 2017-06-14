module LanguageServer

import IO;
import String;
import Map;
import util::Webserver;

// Address of the server
loc addr = |http://localhost:12366|;

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
  Response resp = jsonResponse(ok(), (), message(1));
  println("Request arrived");
  return resp;
}

//void main(list[str] args) {
//  println("Starting language server");
//  startServer();
//}