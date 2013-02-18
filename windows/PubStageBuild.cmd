:: need to clean and rebuild because property overrides are embedded into the app at build stage
:: this does not work: /p:AssemblyName=LiveReloadStage
msbuild /t:clean,rebuild,publish "/p:ProductName=LiveReload Stage" /p:InstallUrl=http://download.livereload.com/windows-stage/ /p:UpdateUrl=http://download.livereload.com/windows-stage/
ren bin\Debug\app.publish\setup.exe LiveReloadStageSetup.exe
