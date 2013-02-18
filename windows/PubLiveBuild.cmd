:: need to clean and rebuild because property overrides are embedded into the app at build stage
msbuild /t:clean,rebuild,publish
ren bin\Debug\app.publish\setup.exe LiveReloadSetup.exe
