cd "%~dp0"

del /q res\bundled\plugins.7z
tools\7za.exe a -xr!.git res\bundled\plugins.7z ..\plugins
