@echo off
rem ---------------------------------------------------------------------------
rem  LAST LAUNCH - Web version.
rem  Do NOT double-click index.html: the browser cannot load the .pck/.wasm from
rem  file:// . This script starts a tiny local web server and opens the game.
rem  Close this window when you are done playing.
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

if not exist "index.html" (
  echo [X] index.html was not found. Extract the whole Web ZIP first.
  pause
  exit /b 1
)

where python >nul 2>nul
if not errorlevel 1 goto :python

where py >nul 2>nul
if not errorlevel 1 goto :py

goto :powershell_server

:python
echo Starting the Web build on http://localhost:8000/ ...
start "" powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 1; Start-Process 'http://localhost:8000/'"
python -m http.server 8000
exit /b

:py
echo Starting the Web build on http://localhost:8000/ ...
start "" powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 1; Start-Process 'http://localhost:8000/'"
py -3 -m http.server 8000
exit /b

:powershell_server
echo Starting the built-in web server (no Python needed) ...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve_web.ps1"
