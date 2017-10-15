@echo off
setlocal EnableDelayedExpansion
setlocal EnableExtensions

echo ^>^> Downloading bundled Node
node .\script\download-node.js

echo.
for /f "delims=" %%i in ('.\bin\node.exe -p "process.version + ' ' + process.arch"') do set bundledVersion=%%i
echo ^>^> Rebuilding vpm dependencies with bundled Node !bundledVersion!
call .\bin\npm.cmd rebuild

echo.
echo ^>^> Deduping vpm dependencies
call .\bin\npm.cmd dedupe
