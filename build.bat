@echo off
setlocal
rem Build Simple Planes for Minecraft 1.21.1 / Fabric using an installed Gradle 8.14.6.
rem If you extracted gradle-8.14.6 next to this project, it is detected automatically.
set "PROJECT_DIR=%~dp0"
where java >nul 2>nul
if errorlevel 1 (
  echo ERROR: Java was not found. Install JDK 21 and add it to PATH.
  pause
  exit /b 1
)
java -version 2>&1 | findstr /C:"21." >nul
if errorlevel 1 (
  echo WARNING: This project targets Java 21. Check that java -version reports JDK 21.
)
set "LOCAL_GRADLE=%PROJECT_DIR%..\gradle-8.14.6\bin\gradle.bat"
if exist "%LOCAL_GRADLE%" (
  call "%LOCAL_GRADLE%" -p "%PROJECT_DIR%" build --no-daemon
  if errorlevel 1 goto build_failed
) else (
  where gradle >nul 2>nul
  if errorlevel 1 (
    echo ERROR: Gradle was not found.
    echo Extract gradle-8.14.6 beside this project, or install Gradle and add it to PATH.
    pause
    exit /b 1
  )
  call gradle -p "%PROJECT_DIR%" build --no-daemon
  if errorlevel 1 goto build_failed
)
echo.
echo BUILD SUCCEEDED. Mod JARs are in build\libs\
for %%F in ("%PROJECT_DIR%build\libs\*.jar") do if exist "%%~fF" echo %%~nxF
pause
exit /b 0

:build_failed
echo.
echo BUILD FAILED. Read the first error above. A network connection is required to download Fabric/Minecraft dependencies.
pause
exit /b 1
