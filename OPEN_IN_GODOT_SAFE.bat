@echo off
rem ---------------------------------------------------------------------------
rem  Same as OPEN_IN_GODOT.bat, but forces the OpenGL 3.3 renderer.
rem  Use this only if the normal editor window fails to start (driver error).
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

if not exist "project.godot" (
  echo [X] project.godot is missing here: %CD%
  echo     Open the folder that contains project.godot.
  pause
  exit /b 1
)

set "GODOT="
if exist "Godot_v4.7.2-stable_win64.exe" set "GODOT=Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "..\Godot_v4.7.2-stable_win64.exe" set "GODOT=..\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "Godot_v4.7.2-stable_win64_console.exe" set "GODOT=Godot_v4.7.2-stable_win64_console.exe"
if not defined GODOT if exist "..\Godot_v4.7.2-stable_win64_console.exe" set "GODOT=..\Godot_v4.7.2-stable_win64_console.exe"

if not defined GODOT (
  echo [!] Godot 4.7.2 not found. Put it in this folder or its parent.
  pause
  exit /b 1
)

echo Opening the project with the safe OpenGL renderer ...
start "" "%GODOT%" --path "%CD%" -e --rendering-method gl_compatibility --rendering-driver opengl3
