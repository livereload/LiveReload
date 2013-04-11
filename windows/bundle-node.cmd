set VER=0.10.3

cd "%~dp0"

rd /s /q node

tools\curl -O "http://nodejs.org/dist/v%VER%/node.exe"

md "node-%VER%"
move node.exe "node-%VER%\LiveReloadNodejs.exe"

del /q /f "res\bundled\node-%VER%.7z"
tools\7za.exe a "res\bundled\node-%VER%.7z" "node-%VER%"

rd /s /q "node-%VER%"
