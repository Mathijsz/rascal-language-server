# rascal-language-server

Experimental project that aims to provide a [language server](https://github.com/Microsoft/language-server-protocol) for [Rascal](http://www.rascal-mpl.org/).

## How to run

Please note that functionality is very limited.

1. Install the 'vscode-client' plugin for Visual Studio Code so that it can connect to a running language server

    ```cd vscode-client && npm install .```

1. Make sure [rls-tunnel.py](experiments/rls-tunnel.py) is in your $PATH. Alternatively, compile rls-tunnel.c and put the executable in your path.
1. Load the LanguageServer module in either the Rascal CLI REPL or the Rascal Eclipse plugin console and register a language with a handler.
1. Run 'startServer();' (to stop, run 'stopServer();')
1. Start VS Code from the 'vscode-client' directory:

    ```npm run vscode```

    For Windows, substitute vscode for vscode-windows.

    For other editors, follow the instructions of the client plugin for that editor. Make sure the LSP plugin executes the server with `rls-tunnel <languageName>`. Also take note of the 'Other editors' paragraph below.
1. Optional: click on 'Help' → 'Toggle Developers Tools' (or press Ctrl+Shift+I) to view debugging tools.

## Other editors
Editors still need to know what type of file is open, so that they can communicate with the corresponding language server. However, by default, languages implemented in Rascal won't typically be recognized in editors. So in addition to mapping language name to language server in the LSP client plugins, these languages will also need a (syntax) plugin effectively mapping file type to language name. Some editors (VSCode, ST3) will use a `*.tmLanguage` file or equivalent for this, though you can get away with just adding keys for `fileTypes` and `scopeName` and ignore all syntax highlighting entries. Such a very minimal `tmLanguage` file may look like this:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>scopeName</key>
        <string>source.LANGUAGE</string>
        <key>fileTypes</key>
        <array>
            <string>ext</string>
            <string>extension</string>
        </array>
        <key>name</key>
        <string>Our LANGUAGE</string>
        <key>uuid</key>
        <string>c330cef6-be7a-41a4-aadb-e963bd955d3f</string>
    </dict>
</plist>
```

For a language `LANGUAGE` with file extension `*.ext`:

### vim/nvim
Add the following line to `~/.config/nvim/filetype.vim` (OSX/Linux/etc.) or `%LocalAppData%\nvim\filetype.vim` (Windows).

> au BufNewFile,BufRead *.ext       setf LANGUAGE

### Sublime Text 3
Hit Preferences -> Browse Packages. Here, create a folder with name `LANGUAGE`. Add a `*.tmLanguage` file to the folder. Optionally, enter Create Package File in the Command Pallete to create a proper `sublime-package` file.

### Visual Studio Code
For VS Code, you will have to make a plugin and add it to your `extensions` folder. A basic `package.json` for our example may look like this

```
{
    "name": "LANGUAGE",
    "displayName": "Language",
    "description": "Adds support for LANGUAGE",
    "version": "0.0.1",
    "engines": {
        "vscode": ">=0.9.0-pre.1"
    },
    "categories": [
        "Languages",
        "Snippets"
    ],
    "publisher": "me",
    "contributes": {
        "languages": [{
            "id": "LANGUAGE",
            "aliases": ["Language", "LANGUAGE"],
            "extensions": [".extension", ".ext"]
        }],
        "grammars": [{
            "language": "rebel",
            "scopeName": "source.LANGUAGE",
            "path": "./syntaxes/LANGUAGE.tmLanguage"
        }]
    }
}
```