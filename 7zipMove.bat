@echo off
setlocal enabledelayedexpansion

REM ================================
REM 7zip.bat - Improved Version
REM ================================
REM Usage: 7zip.bat input_file.txt temp_folder target_folder zip_prefix
REM Description:
REM 1. Compresses files from input_file.txt to temp_folder using 7-Zip (no compression, 10GB volumes).
REM 2. Optionally clears temp_folder before packing.
REM 3. Copies the resulting files to target_folder using TeraCopy.
REM 4. Extracts the ZIP files in target_folder.
REM 5. Deletes the ZIP files.

REM === Enable ANSI color codes ===
REM ANSI color codes: ESC[<color code>m
REM 0=Reset, 31=Red, 32=Green, 33=Yellow, 34=Blue, 35=Magenta, 36=Cyan, 37=White, 90=Gray
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "COLOR_RESET=%ESC%[0m"
set "COLOR_RED=%ESC%[31m"
set "COLOR_GREEN=%ESC%[32m"
set "COLOR_YELLOW=%ESC%[33m"
set "COLOR_BLUE=%ESC%[34m"
set "COLOR_MAGENTA=%ESC%[35m"
set "COLOR_CYAN=%ESC%[36m"
set "COLOR_WHITE=%ESC%[37m"
set "COLOR_GRAY=%ESC%[90m"

REM === Argument Validation ===
if "%~3"=="" (
    echo %COLOR_RED%Usage: %~nx0 input_file.txt temp_folder target_folder zip_prefix%COLOR_RESET%
    echo.
    echo Example:
    echo     %~nx0 myfiles.txt C:\Temp\ZipOut D:\Backup archive_files
    exit /b 1
)

REM === Variable Definitions ===
set "input_file=%~1"
set "outputDir=%~2"
set "target_path=%~3"

REM === Sanitize zip_prefix to avoid special characters ===
set "zip_prefix=%~4"

REM === Check zip_prefix is not empty, if empty, set Archive name to "Archive" ===
echo %COLOR_CYAN%[INFO] zip_prefix: "%zip_prefix%"%COLOR_RESET%
if "%~4"=="" (
    set "zip_prefix=Archive"
)

REM Replace spaces with underscores
set "zip_prefix=%zip_prefix: =_%"
REM Remove parentheses
set "zip_prefix=%zip_prefix:(=%"
set "zip_prefix=%zip_prefix:)=%"
REM Remove other problematic characters
set "zip_prefix=%zip_prefix:&=_%"
set "zip_prefix=%zip_prefix:^=_%"
set "zip_prefix=%zip_prefix:>=_%"
set "zip_prefix=%zip_prefix:<=_%"
set "zip_prefix=%zip_prefix:|=_%"

set "zipFileName=%outputDir%\%zip_prefix%.zip"
set "sevenzip=C:\Program Files\7-Zip\7z.exe"
set "teracopy=C:\Program Files\TeraCopy\TeraCopy.exe"

REM === File/Folder Checks ===
if not exist "%input_file%" (
    echo %COLOR_RED%[ERROR] Input file not found: %input_file%%COLOR_RESET%
    exit /b 1
)

if not exist "%sevenzip%" (
    echo %COLOR_RED%[ERROR] 7-Zip not found at: %sevenzip%%COLOR_RESET%
    exit /b 1
)

if not exist "%teracopy%" (
    echo %COLOR_RED%[ERROR] TeraCopy not found at: %teracopy%%COLOR_RESET%
    exit /b 1
)

if not exist "%outputDir%" (
    echo %COLOR_CYAN%[INFO] Output folder not found. Creating: %outputDir%%COLOR_RESET%
    mkdir "%outputDir%"
)

REM === Clear Temp Folder Prompt ===
echo.
echo %COLOR_CYAN%[INFO] Temp folder: "%outputDir%"%COLOR_RESET%
echo %COLOR_CYAN%[INFO] Archive name: "%zip_prefix%"%COLOR_RESET%
REM set /p clear_temp=Delete all contents of this folder (Y/N)? 

REM if /i "!clear_temp!"=="Y" (
    echo %COLOR_CYAN%[INFO] Clearing temp folder...%COLOR_RESET%
    rmdir /s /q "%outputDir%"
    echo %COLOR_CYAN%[INFO] Temp folder cleared.%COLOR_RESET%
    echo %COLOR_CYAN%[INFO] Recreating temp folder...%COLOR_RESET%
    mkdir "%outputDir%"
    if errorlevel 1 (
        echo %COLOR_RED%[ERROR] Failed to clear or recreate the folder.%COLOR_RESET%
        exit /b 1
    )
    echo %COLOR_CYAN%[INFO] Temp folder recreated.%COLOR_RESET%
REM ) else (
REM    echo %COLOR_CYAN%[INFO] Temp folder not cleared.%COLOR_RESET%
REM )

REM === Compression Process ===
echo.
echo %COLOR_CYAN%[INFO] Compressing files listed in "%input_file%"...%COLOR_RESET%
echo %COLOR_CYAN%[INFO] Using sanitized archive name: %zip_prefix%.zip%COLOR_RESET%
"%sevenzip%" a -tzip -mmt=16 -mx0 -v10g "%zipFileName%" "@%input_file%" -bb
if errorlevel 1 (
    echo %COLOR_RED%[ERROR] Compression failed.%COLOR_RESET%
    pause
    exit /b 1
)
echo %COLOR_CYAN%[INFO] Compression complete.%COLOR_RESET%

REM === Move to Target Folder ===
echo.
echo %COLOR_CYAN%[INFO] Starting move to: "%target_path%"%COLOR_RESET%
start /wait "" "%teracopy%" move "%outputDir%\*" "%target_path%" /Close
if errorlevel 1 (
    echo %COLOR_RED%[ERROR] Move failed.%COLOR_RESET%
    pause
    exit /b 1
)
echo %COLOR_CYAN%[INFO] Move complete.%COLOR_RESET%

REM === Extract ZIP Files at Target ===
echo.
echo %COLOR_CYAN%[INFO] Extracting ZIP files in "%target_path%"%COLOR_RESET%

REM Hedef klasördeki dosyaları kontrol et
echo %COLOR_CYAN%[INFO] Checking target directory for archives...%COLOR_RESET%
dir "%target_path%\%zip_prefix%.zip*" /b 2>nul

REM Bölünmüş arşivleri doğru şekilde işleme
set "found_archive=false"

REM İlk olarak .001 uzantılı dosyaları kontrol et
if exist "%target_path%\%zip_prefix%.zip.001" (
    echo %COLOR_CYAN%[INFO] Found split archive: %zip_prefix%.zip.001%COLOR_RESET%
    echo %COLOR_CYAN%[INFO] Extracting all volumes at once...%COLOR_RESET%
    
    "%sevenzip%" x "%target_path%\%zip_prefix%.zip.001" -o"%target_path%" -aoa -mmt=on
    if errorlevel 1 (
        echo %COLOR_RED%[ERROR] Failed to extract split archive.%COLOR_RESET%
        pause
        exit /b 1
    )
    echo .
    echo %COLOR_CYAN%[INFO] Split archive extraction complete.%COLOR_RESET%
    
    echo %COLOR_CYAN%[INFO] Deleting all archive volumes...%COLOR_RESET%
    for %%F in ("%target_path%\%zip_prefix%.zip.*") do (
        echo %COLOR_CYAN%[INFO] Deleting ZIP file: %%~nxF%COLOR_RESET%
        del /f /q "%%F" 2>nul
        if exist "%%F" (
            powershell -Command "Remove-Item -Path '%%F' -Force" 2>nul
        )
        if exist "%%F" (
            echo %COLOR_YELLOW%[WARNING] Could not delete ZIP file: %%F%COLOR_RESET%
        ) else (
            echo %COLOR_CYAN%[INFO] ZIP file deleted successfully.%COLOR_RESET%
        )
    )
    set "found_archive=true"
) else (
    echo %COLOR_CYAN%[INFO] No split archive found with pattern: %target_path%\%zip_prefix%.zip.001%COLOR_RESET%
)

REM Tek parça arşiv kontrolü
if exist "%target_path%\%zip_prefix%.zip" (
    echo %COLOR_CYAN%[INFO] Found single archive: %zip_prefix%.zip%COLOR_RESET%
    echo %COLOR_CYAN%[INFO] Extracting single archive...%COLOR_RESET%
    
    "%sevenzip%" x "%target_path%\%zip_prefix%.zip" -o"%target_path%" -aoa -mmt=on
    if errorlevel 1 (
        echo %COLOR_RED%[ERROR] Failed to extract single archive.%COLOR_RESET%
        pause
        exit /b 1
    )
    echo %COLOR_CYAN%[INFO] Single archive extraction complete.%COLOR_RESET%
    
    echo %COLOR_CYAN%[INFO] Deleting archive file...%COLOR_RESET%
    del /f /q "%target_path%\%zip_prefix%.zip" 2>nul
    if exist "%target_path%\%zip_prefix%.zip" (
        powershell -Command "Remove-Item -Path '%target_path%\%zip_prefix%.zip' -Force" 2>nul
    )
    if exist "%target_path%\%zip_prefix%.zip" (
        echo %COLOR_YELLOW%[WARNING] Could not delete ZIP file: %zip_prefix%.zip%COLOR_RESET%
    ) else (
        echo %COLOR_CYAN%[INFO] ZIP file deleted successfully.%COLOR_RESET%
    )
    set "found_archive=true"
) else (
    echo %COLOR_CYAN%[INFO] No single archive found with pattern: %target_path%\%zip_prefix%.zip%COLOR_RESET%
)

if "%found_archive%"=="false" (
    echo %COLOR_YELLOW%[WARNING] No archives found to extract! Please check file names and paths.%COLOR_RESET%
    echo %COLOR_CYAN%[INFO] Expected patterns:%COLOR_RESET%
    echo %COLOR_CYAN%[INFO] - %target_path%\%zip_prefix%.zip.001%COLOR_RESET%
    echo %COLOR_CYAN%[INFO] - %target_path%\%zip_prefix%.zip%COLOR_RESET%
    pause
)

REM === Clean Temp Folder ===
echo.
echo %COLOR_CYAN%[INFO] Cleaning ZIP files in "%outputDir%"%COLOR_RESET%
for %%F in ("%outputDir%\%zip_prefix%.zip*") do (
    echo %COLOR_CYAN%[INFO] Deleting temp ZIP file: %%~nxF%COLOR_RESET%
    
    REM Try different deletion methods for problematic filenames
    del /f /q "%%F" 2>nul
    if exist "%%F" (
        REM Try with 8.3 short filename
        for %%S in ("%%F") do (
            if exist "%%~sS" (
                del /f /q "%%~sS" 2>nul
            )
        )
    )
    if exist "%%F" (
        REM Try with PowerShell as last resort
        powershell -Command "Remove-Item -Path '%%F' -Force" 2>nul
    )
    
    if exist "%%F" (
        echo %COLOR_YELLOW%[WARNING] Could not delete temp ZIP file: %%F%COLOR_RESET%
    ) else (
        echo %COLOR_CYAN%[INFO] Temp ZIP file deleted successfully.%COLOR_RESET%
    )
)
echo %COLOR_CYAN%[INFO] Temp folder cleanup complete.%COLOR_RESET%

echo.
echo %COLOR_GREEN%[SUCCESS] Operation finished successfully.%COLOR_RESET%
pause