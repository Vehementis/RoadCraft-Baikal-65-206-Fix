@echo off
setlocal enabledelayedexpansion

:: ========================================
echo RoadCraft Baikal 65-206 Fix Installer
echo ========================================
echo.
echo NOTE: If you run this script as Administrator, 7-Zip will install silently if missing.
echo.
echo Press any key to continue...
pause >nul

:: Set initial error flag
set "ERROR_OCCURRED=0"
set "LOG_FILE=%~dp0installer_log.txt"
if exist "%LOG_FILE%" del "%LOG_FILE%"

:: Set start directory and backup folder
set "START_DIR=%~dp0"
set "ROADCRAFT_ROOT="
set "BACKUP_DIR=%START_DIR%backup"

:: Create backup folder if it doesn't exist
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Locate RoadCraft installation
echo Searching for RoadCraft installation...
echo Searching for RoadCraft installation... >> "%LOG_FILE%"

set "COMMON_PATH=%ProgramFiles(x86)%\Steam\steamapps\common"
set "ROADCRAFT_INSTALL_PATH=%COMMON_PATH%\RoadCraft"
set "DEFAULT_OTHER_PATH=%ROADCRAFT_INSTALL_PATH%\root\paks\client\default\default_other.pak"

if exist "%DEFAULT_OTHER_PATH%" (
    set "ROADCRAFT_ROOT=%ROADCRAFT_INSTALL_PATH%"
    echo Found RoadCraft at: %ROADCRAFT_ROOT%
    echo Found RoadCraft at: %ROADCRAFT_ROOT% >> "%LOG_FILE%"
    goto :FOUND_ROOT
)

:: Fallback search
echo Not found in default Steam path, searching manually...
echo Not found in default Steam path, searching manually... >> "%LOG_FILE%"
set "FOUND_PAK="
for /r "%START_DIR%" %%F in (default_other.pak) do (
    if not defined FOUND_PAK (
        set "FOUND_PAK=%%~fF"
    )
)

if defined FOUND_PAK (
    set "ROADCRAFT_ROOT=%FOUND_PAK:\root\paks\client\default\default_other.pak=%"
    echo Found default_other.pak at: "%FOUND_PAK%"
    echo Found default_other.pak at: "%FOUND_PAK%" >> "%LOG_FILE%"
    echo Inferring install root: "%ROADCRAFT_ROOT%"
    echo Inferring install root: "%ROADCRAFT_ROOT%" >> "%LOG_FILE%"
    goto :FOUND_ROOT
)

echo ERROR: RoadCraft installation not found!
echo ERROR: RoadCraft installation not found! >> "%LOG_FILE%"
echo Expected location: %DEFAULT_OTHER_PATH%
echo Please ensure the fix is placed near your RoadCraft install.
echo.
pause
exit /b 1

:FOUND_ROOT
for %%I in ("%ROADCRAFT_ROOT%") do set "ROADCRAFT_ROOT=%%~fI"
echo.
echo RoadCraft root resolved to: %ROADCRAFT_ROOT%
echo RoadCraft root resolved to: %ROADCRAFT_ROOT% >> "%LOG_FILE%"

:: Check for full 7-Zip install (7z.exe)
set "SEVENZIP="
set "ZIP_URL=https://www.7-zip.org/a/7z2201-x64.exe"
set "ZIP_INSTALLER=%TEMP%\7zsetup.exe"

if exist "%ProgramFiles%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"
if exist "%ProgramW6432%\7-Zip\7z.exe" set "SEVENZIP=%ProgramW6432%\7-Zip\7z.exe"

if not defined SEVENZIP (
    echo 7-Zip full install not found. Downloading 7-Zip installer...
    echo 7-Zip full install not found. Downloading 7-Zip installer... >> "%LOG_FILE%"
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_INSTALLER%'" >> "%LOG_FILE%" 2>&1

    if exist "%ZIP_INSTALLER%" (
        echo Installing 7-Zip silently...
        echo Installing 7-Zip silently... >> "%LOG_FILE%"
        "%ZIP_INSTALLER%" /S
        timeout /t 5 >nul

        if exist "%ProgramFiles%\7-Zip\7z.exe" (
            set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
        ) else if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" (
            set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"
        ) else (
            echo ERROR: 7-Zip installation failed.
            echo ERROR: 7-Zip installation failed. >> "%LOG_FILE%"
            pause
            exit /b 1
        )

        del /f /q "%ZIP_INSTALLER%"
        echo 7-Zip installed successfully.
        echo 7-Zip installed successfully. >> "%LOG_FILE%"
    ) else (
        echo ERROR: Failed to download 7-Zip installer.
        echo ERROR: Failed to download 7-Zip installer. >> "%LOG_FILE%"
        pause
        exit /b 1
    )
) else (
    echo 7-Zip found at: %SEVENZIP%
    echo 7-Zip found at: %SEVENZIP% >> "%LOG_FILE%"
)

:: Timestamp for backups
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"

set "PAK_PATH=%ROADCRAFT_ROOT%\root\paks\client\default\default_other.pak"
set "BACKUP_FILE1=ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_old\auto_baikal_65206_heavy_dumptruck_old.cls"
set "BACKUP_FILE2=ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_res\auto_baikal_65206_heavy_dumptruck_res.cls"

echo.
echo Backing up original files...
echo Backing up original files... >> "%LOG_FILE%"

if exist "%PAK_PATH%.cache" (
    copy "%PAK_PATH%.cache" "%BACKUP_DIR%\default_other.pak.cache.backup_%timestamp%" >> "%LOG_FILE%" 2>&1
    echo [OK] Backed up cache file
)

"%SEVENZIP%" e "%PAK_PATH%" "%BACKUP_FILE1%" -o"%BACKUP_DIR%" -y >> "%LOG_FILE%" 2>&1
if exist "%BACKUP_DIR%\auto_baikal_65206_heavy_dumptruck_old.cls" ren "%BACKUP_DIR%\auto_baikal_65206_heavy_dumptruck_old.cls" "auto_baikal_65206_heavy_dumptruck_old.cls.backup_%timestamp%"

"%SEVENZIP%" e "%PAK_PATH%" "%BACKUP_FILE2%" -o"%BACKUP_DIR%" -y >> "%LOG_FILE%" 2>&1
if exist "%BACKUP_DIR%\auto_baikal_65206_heavy_dumptruck_res.cls" ren "%BACKUP_DIR%\auto_baikal_65206_heavy_dumptruck_res.cls" "auto_baikal_65206_heavy_dumptruck_res.cls.backup_%timestamp%"

echo.
echo Applying fix...
echo Applying fix... >> "%LOG_FILE%"

if exist "%PAK_PATH%.cache" del "%PAK_PATH%.cache"

"%SEVENZIP%" a "%PAK_PATH%" "%~dp0default_other\%BACKUP_FILE1%" >> "%LOG_FILE%" 2>&1
if errorlevel 1 set "ERROR_OCCURRED=1"

"%SEVENZIP%" a "%PAK_PATH%" "%~dp0default_other\%BACKUP_FILE2%" >> "%LOG_FILE%" 2>&1
if errorlevel 1 set "ERROR_OCCURRED=1"

echo.
echo ========================================
if "%ERROR_OCCURRED%"=="1" (
    echo Installation completed with some errors! See installer_log.txt
) else (
    echo Installation completed successfully!
)

echo Backup files are stored in: %BACKUP_DIR%
echo Log file saved to: %LOG_FILE%
echo.
echo Press any key to exit...
pause >nul
exit /b
