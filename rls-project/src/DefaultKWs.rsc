module DefaultKWs

import lang::rascal::\syntax::Rascal;
import ParseTree;
import IO;
import Node;
import util::Reflective;
import util::Eval;
import String;
import Type;

loc prot = |project://rls-project/src/Protocol.rsc|;

map[str,value] getDefaultKeywordParams(str constrName) {
  return getDefaultKeywordParams(constrName, []);
}

map[str,value] getDefaultKeywordParams(str constrName, list[str] parameters) {

  map[str,value] defaultKWs = ();

  if (endsWith(constrName, "()"))
    constrName = substring(constrName, 0, size(constrName) - 2);

  if ((start[Module])`<Module m>` := parse(#start[Module], readFile(prot))) {

    visit (m) {
      case \nAryConstructor(name, args, kwargs): {
        if ("<name>" == constrName) {
          argList = [ split(" ", s)[1]?"" | s <- split(", ", "<args>"), s != "" ];
          if (size(argList) == 0 || argList == parameters) {
            visit (kwargs) {
              case (KeywordFormal)`<Type t> <Name n> = <Expression e>`: {
                bool isData = "<t>" notin getRascalReservedIdentifiers();
                bool isMap = contains("<e>", "[");
                argToEvaluate = "<e>;";
                if (isData || isMap)
                  argToEvaluate = "import Protocol; " + argToEvaluate;
                res = eval(argToEvaluate);
                if (res is \result) {
                  if (isData)
                    setKeywordParameters(res.val, getDefaultKeywordParams("<e>"));
                  defaultKWs["<n>"] = res.val;
                }
              }
            } 
          }
        }
      }
    }
  }

  return defaultKWs;
}