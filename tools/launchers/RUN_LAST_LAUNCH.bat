@echo off
rem ---------------------------------------------------------------------------
rem  LAST LAUNCH - normal Windows launch with automatic renderer fallback.
rem
rem  Some school laptops / virtual machines cannot start the game with the
rem  default renderer (Vulkan / Forward+) and show:
rem      "Unable to initialize video driver"
rem  This script then retries the same exe with the OpenGL 3.3 renderer and only
rem  gives up when both fail.
rem
rem  If both fail, the PC has no usable 3D driver at all (common on virtual
rem  machines, remote desktop sessions and very old laptops) - use the browser
rem  version instead: PLAY_WEB.bat needs no driver.
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

if not exist "OGFrontier.exe" (
  echo.
  echo [X] OGFrontier.exe was not found next to this file.
  echo     Extract the whole ZIP first, then run RUN_LAST_LAUNCH.bat
  echo     from inside the extracted folder.
  echo.
  pause
  exit /b 1
)

echo.
echo  LAST LAUNCH - starting the game...
echo  If Windows asks about SmartScreen: More info - Run anyway.
echo.

"OGFrontier.exe"
if not errorlevel 1 goto :done

echo.
echo [!] The game did not start.
echo     Retrying with the OpenGL 3.3 renderer...
echo.
"OGFrontier.exe" --rendering-method gl_compatibility --rendering-driver opengl3
if not errorlevel 1 goto :done

echo.
echo ============================================================
echo  This PC has no working 3D driver for the Windows build.
echo  It reports no Vulkan and no OpenGL 3.3 - common on virtual
echo  machines, remote desktop sessions and very old laptops.
echo.
echo  Use the browser version instead - it needs no driver:
echo    1. Extract LastLaunch_v0.4.1_Web.zip
echo    2. Run PLAY_WEB.bat
echo ============================================================
echo.
pause
exit /b 1

:done
exit /b 0
