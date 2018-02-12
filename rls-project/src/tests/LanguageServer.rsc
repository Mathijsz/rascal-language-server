module tests::LanguageServer

import LanguageServer;
import Protocol;

import IO;
import Node;
import Check;

LSPResponse testHandler(LSPRequest lspReq) {
  println("got request: <getName(lspReq)>");
  switch (lspReq) {
    case initialize(): {
      //return initializeResult(capabilities=capabilities(textDocumentSync=2,hoverProvider=true));
      return initializeResult();
    }
    case didOpen(_): {
      println("didOpen (<lspReq.textDocument.uri>)");
      return none();
    }
    case didClose(_): {
      println("didClose (<lspReq.textDocument.uri>)");
      return none();
    }
    case hover(_): {
      println("hover request (<lspReq.textDocument.uri>)");
      return hoverResult("teststring");
    }
    case shutdown(): {
      println("shutdown");
      return none();
    }
    case exit(): {
      println("client exited");
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