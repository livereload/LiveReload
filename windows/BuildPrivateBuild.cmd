set dotnetver=v4.0.30319
set msbuild=%systemroot%\Microsoft.NET\Framework\%dotnetver%\MSBuild.exe

:: need to clean and rebuild because property overrides are embedded into the app at build stage
"%msbuild%" /t:clean,rebuild,publish /p:ApplicationVersion=0.0.0.0 /p:InstallFrom=Disk /p:IsWebBootstrapper=false
