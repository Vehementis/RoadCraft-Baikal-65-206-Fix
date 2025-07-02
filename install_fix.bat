@echo off
setlocal enabledelayedexpansion

echo ========================================
echo RoadCraft Baikal 65-206 Fix Installer
echo ========================================
echo.

set "ERROR_OCCURRED=0"

:: Check if we're in the correct directory
if not exist "default_other" (
    echo ERROR: default_other folder not found!
    echo Please make sure you've extracted the RoadCraft-Baikal-65-206-Fix-main.zip
    echo and placed this folder inside your RoadCraft installation directory.
    echo.
    pause
    exit /b 1
)

set "MOD_ROOT=%CD%"

:: Find RoadCraft root directory (go up one level)
cd ..
set "ROADCRAFT_ROOT=%CD%"

echo RoadCraft installation detected at: %ROADCRAFT_ROOT%
echo.

:: Verify RoadCraft installation
if not exist "root\paks\client\default\default_other.pak" (
    echo ERROR: RoadCraft installation not found!
    echo Could not locate: root\paks\client\default\default_other.pak
    echo Please ensure the RoadCraft-Baikal-65-206-Fix-main folder is placed
    echo directly inside your RoadCraft installation directory.
    echo.
    pause
    exit /b 1
)

:: Check for 7-Zip
set "SEVENZIP="
if exist "%ProgramFiles%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"
if exist "%ProgramW6432%\7-Zip\7z.exe" set "SEVENZIP=%ProgramW6432%\7-Zip\7z.exe"

if "%SEVENZIP%"=="" (
    echo ERROR: 7-Zip not found!
    echo Please install 7-Zip from https://www.7-zip.org/
    echo This script requires 7-Zip to modify the game files safely.
    echo.
    pause
    exit /b 1
)

echo 7-Zip found at: %SEVENZIP%
echo.

:: Create backup directory
set "BACKUP_DIR=%MOD_ROOT%\backup"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Creating backup of original files...

:: Create timestamp for backup
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"

:: Backup the .pak.cache file if it exists
if exist "root\paks\client\default\default_other.pak.cache" (
    echo Backing up default_other.pak.cache...
    copy "root\paks\client\default\default_other.pak.cache" "%BACKUP_DIR%\default_other.pak.cache.backup_%timestamp%" >nul
    if !errorlevel! equ 0 (
        echo [OK] Cache file backed up successfully
    ) else (
        echo [WARNING] Failed to backup cache file
    )
)

:: Backup original files from the PAK
echo Extracting and backing up original truck files...
"%SEVENZIP%" e "root\paks\client\default\default_other.pak" "ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_old\auto_baikal_65206_heavy_dumptruck_old.cls" -o"%BACKUP_DIR%" -y >nul 2>&1
if !errorlevel! equ 0 (
    ren "%BACKUP_DIR%\auto_baikal_65206_heavy_dumptruck_old.cls" "auto_baikal_65206_heavy_dumptruck_old.cls.backup_%timestamp%"
    echo [OK] Backed up auto_baikal_65206_heavy_dumptruck_old.cls
) else (
    echo [WARNING] Could not backup auto_baikal_65206_heavy_dumptruck_old.cls (file may not exist)
)

"%SEVENZIP%" e "root\paks\client\default\default_other.pak" "ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_res\auto_baikal_65206_heavy_dumptruck_res.cls" -o"%BACKUP_DIR%" -y >nul 2>&1
if !errorlevel! equ 0 (
    ren "%BACKUP_DIR%\auto_baikal_65206_heavy_dumptruck_res.cls" "auto_baikal_65206_heavy_dumptruck_res.cls.backup_%timestamp%"
    echo [OK] Backed up auto_baikal_65206_heavy_dumptruck_res.cls
) else (
    echo [WARNING] Could not backup auto_baikal_65206_heavy_dumptruck_res.cls (file may not exist)
)

echo.
echo Applying fix...

:: Delete the cache file
if exist "root\paks\client\default\default_other.pak.cache" (
    echo Deleting cache file...
    del "root\paks\client\default\default_other.pak.cache"
    if !errorlevel! equ 0 (
        echo [OK] Cache file deleted successfully
    ) else (
        echo [ERROR] Failed to delete cache file
        echo You may need to run this script as Administrator
    )
) else (
    echo [INFO] Cache file not found (this is normal)
)

:: Change to the fix directory to maintain correct folder structure
cd "RoadCraft-Baikal-65-206-Fix-main\default_other"

:: Update files in the PAK using 7-Zip with correct paths
echo Updating truck files in default_other.pak...

:: Update first truck file - use relative path from default_other folder
"%SEVENZIP%" a "..\..\root\paks\client\default\default_other.pak" "ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_old\auto_baikal_65206_heavy_dumptruck_old.cls" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Updated auto_baikal_65206_heavy_dumptruck_old.cls
) else (
    echo [ERROR] Failed to update auto_baikal_65206_heavy_dumptruck_old.cls
    set "ERROR_OCCURRED=1"
)

:: Update second truck file - use relative path from default_other folder
"%SEVENZIP%" a "..\..\root\paks\client\default\default_other.pak" "ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_res\auto_baikal_65206_heavy_dumptruck_res.cls" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Updated auto_baikal_65206_heavy_dumptruck_res.cls
) else (
    echo [ERROR] Failed to update auto_baikal_65206_heavy_dumptruck_res.cls
    set "ERROR_OCCURRED=1"
)

:: Return to original directory
cd "%MOD_ROOT%"

echo.
echo ========================================

if "%ERROR_OCCURRED%"=="1" (
    echo Installation completed with some errors!
    echo Please check the messages above and try running as Administrator if needed.
) else (
    echo Installation completed successfully!
    echo The Baikal 65-206 sand spill fix has been applied.
	echo.
	echo You can now start RoadCraft and test the fix.
)

echo.
echo Backup files are stored in: %BACKUP_DIR%
echo.
echo If you encounter any issues, you can restore the original files
echo from the backup folder.
echo.
pause
