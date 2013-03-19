set VER=0.8.4
set PKG=livereload-%VER%

cd "%~dp0"

rd /s /q backend
rd /s /q package
del /q /f "%PKG%.tar"

tools\curl -O "http://download.livereload.com/npm/%PKG%.tgz"
tools\7za x "%PKG%.tgz"
tools\7za x "%PKG%.tar"
del /q /f "%PKG%.tar"
ren package backend

for /d /r . %%d in (test example examples) do @if exist "%%d" rd /s/q "%%d"

del /q res\bundled\backend.7z
tools\7za.exe a res\bundled\backend.7z backend
