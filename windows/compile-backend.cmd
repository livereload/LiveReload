cd "%~dp0\..\node_modules"
echo :: automatically generated > "%~dp0\compile-backend-files.cmd"
echo cd %~dp0..\node_modules >> "%~dp0\compile-backend-files.cmd"
node "%~dp0\tools\compiler\compile-backend.js" >> "%~dp0\compile-backend-files.cmd"
