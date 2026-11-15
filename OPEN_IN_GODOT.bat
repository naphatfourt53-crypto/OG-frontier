@echo off
rem ---------------------------------------------------------------------------
rem  LAST LAUNCH / OG-FRONTIER - open THIS folder in the Godot 4.7.2 editor.
rem  If Godot says "Can't open file 'menu.tscn'", you opened the wrong folder:
rem  the editor must be pointed at the folder that contains project.godot.
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

if not exist "project.godot" (
  echo.
  echo [X] project.godot was not found in this folder:
  echo     %CD%
  echo.
  echo     Open the folder that contains project.godot, then run this file.
  echo     Do not open the parent folder that only has data, docs, scripts.
  echo.
  pause
  exit /b 1
)

set "GODOT="
if exist "Godot_v4.7.2-stable_win64.exe" set "GODOT=Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "..\Godot_v4.7.2-stable_win64.exe" set "GODOT=..\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "..\..\Godot_v4.7.2-stable_win64.exe" set "GODOT=..\..\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "Godot_v4.7.2-stable_win64_console.exe" set "GODOT=Godot_v4.7.2-stable_win64_console.exe"
if not defined GODOT if exist "..\Godot_v4.7.2-stable_win64_console.exe" set "GODOT=..\Godot_v4.7.2-stable_win64_console.exe"

if not defined GODOT (
  echo.
  echo [!] Godot 4.7.2 was not found next to this folder.
  echo     Download "Godot 4.7.2 - Windows" from https://godotengine.org/download/windows/
  echo     Extract Godot_v4.7.2-stable_win64.exe into this folder or its parent,
  echo     then run OPEN_IN_GODOT.bat again.
  echo.
  pause
  exit /b 1
)

echo Opening the project with %GODOT% ...
start "" "%GODOT%" --path "%CD%" -e
