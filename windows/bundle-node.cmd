set VER=0.10.12

cd "%~dp0"

del /q /f node.exe

tools\curl.exe -O "http://nodejs.org/dist/v%VER%/node.exe"
tools\upx.exe --ultra-brute node.exe

del /q /f res\LiveReloadNodejs.exe
move node.exe res\LiveReloadNodejs.exe


