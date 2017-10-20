module tests::LanguageServer

import LanguageServer;
import Protocol;

import IO;

LSPResponse testHandler(LSPRequest lspReq) {
  switch (lspReq) {
    case initialize(): {
      println("got init");
      return initializeResult(capabilities=capabilities(textDocumentSync=2));
    }
    case didOpen(_): {
      println("got didOpen (<lspReq.textDocument.uri>)");
      return none();
    }
    case shutdown(): {
      println("got shutdown");
      return none();
    }
    default: {
      println("got something else");
      return none();
    }
  }
  return none();
}

void testStart() {
  register("rascal", testHandler);
  startServer();
}

void testStop() {
  deregister("rascal");
  stopServer();
}