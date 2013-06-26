@echo off

set modules=fsmonitor jobqueue livereload livereload-client livereload-core livereload-new livereload-protocol livereload-server newreactive pathspec vfs-local vfs-test

for %%i in (%modules%) do (
    echo.
    echo ==================================
    echo Executing "npm install" in  %%i
    echo ==================================
    echo.

    pushd "%~dp0\..\node_modules\%%i"
    call npm install


    echo.
    echo ==================================
    echo Cleaning up  %%i
    echo ==================================
    echo.

    cd node_modules
    rd /s /q %modules%

    popd
)
