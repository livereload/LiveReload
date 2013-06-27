set pub_folder=bin\Debug\app.publish\


set dotnetver=v4.0.30319
set msbuild=%systemroot%\Microsoft.NET\Framework\%dotnetver%\MSBuild.exe

:: need to clean and rebuild because property overrides are embedded into the app at build stage
"%msbuild%" /t:clean,rebuild,publish /p:InstallFrom=Disk /p:IsWebBootstrapper=false
ren bin\Debug\app.publish\setup.exe LiveReloadSetupOffline.exe


del /q /f "%pub_folder%\ res\bundled\node-%VER%.7z"
tools\7za.exe a "res\bundled\node-%VER%.7z" "node-%VER%"

rd /s /q "node-%VER%"
