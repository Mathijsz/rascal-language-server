# rascal-language-server

Experimental project that aims to provide a [language server](https://github.com/Microsoft/language-server-protocol) for [Rascal](http://www.rascal-mpl.org/).

## How to run

Please note that there isn't any usable functionality (yet) for now.

0. Install the 'vscode-client' plugin for Visual Studio Code so that it can connect to a running language server
`cd vscode-client && npm install .`
0. Make sure [rls-tunnel.py](experiments/rls-tunnel.py) is in your $PATH.
0. Load the LanguageServer module in either the Rascal CLI REPL or the Rascal Eclipse plugin console and register a language.
0. Run 'startServer();' (to stop, run 'stopServer();')
0. Start VS Code from the 'vscode-client' directory:
`npm run vscode`
0. Optional: click on 'Help' → 'Toggle Developers Tools' (or press Ctrl+Shift+I) to view debugging tools.