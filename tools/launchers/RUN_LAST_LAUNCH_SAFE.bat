@echo off
rem ---------------------------------------------------------------------------
rem  LAST LAUNCH - force the OpenGL 3.3 renderer.
rem  Use this when RUN_LAST_LAUNCH.bat shows "Unable to initialize video driver"
rem  (that means the default Vulkan renderer is not available on this PC).
rem  Needs a graphics driver with OpenGL 3.3 (Windows 7 or newer with drivers).
rem  If this also fails, use the browser version: PLAY_WEB.bat.
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

if not exist "OGFrontier.exe" (
  echo [X] OGFrontier.exe is missing. Extract the whole ZIP first.
  pause
  exit /b 1
)

start "" "OGFrontier.exe" --rendering-method gl_compatibility --rendering-driver opengl3
