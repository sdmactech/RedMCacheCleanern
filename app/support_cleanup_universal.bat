@echo off
setlocal enabledelayedexpansion

:: RedM Cache Cleanup Script
:: This script deletes cache, server-cache, and server-cache-priv folders
:: from the RedM data directory for the Windows user who launches it.
:: It can also optionally delete the nui-storage folder if the user confirms.

echo ========================================
echo RedM Cache Cleanup Script
echo ========================================
echo.

:: Set the target directory for the current Windows user
set "TARGET_DIR=%LOCALAPPDATA%\RedM\RedM.app\data"

:: Check if the target directory exists
if not exist "%TARGET_DIR%" (
    echo ERROR: RedM data directory not found!
    echo Expected location: %TARGET_DIR%
    echo.
    echo Please verify RedM is installed for Windows user "%USERNAME%" and the path is correct.
    pause
    exit /b 1
)

echo Windows user: %USERNAME%
echo Target directory: %TARGET_DIR%
echo.
echo The following folders will be deleted:
echo   - cache
echo   - server-cache
echo   - server-cache-priv
echo.

:: Ask for confirmation
set /p "CONFIRM=Are you sure you want to delete these folders? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo.
    echo Operation cancelled by user.
    pause
    exit /b 0
)

echo.
echo Starting cleanup...
echo.

:: Delete cache folder
if exist "%TARGET_DIR%\cache" (
    echo Deleting cache folder...
    rd /s /q "%TARGET_DIR%\cache"
    if !errorlevel! equ 0 (
        echo [SUCCESS] cache folder deleted
    ) else (
        echo [ERROR] Failed to delete cache folder
    )
) else (
    echo [INFO] cache folder not found - skipping
)

:: Delete server-cache folder
if exist "%TARGET_DIR%\server-cache" (
    echo Deleting server-cache folder...
    rd /s /q "%TARGET_DIR%\server-cache"
    if !errorlevel! equ 0 (
        echo [SUCCESS] server-cache folder deleted
    ) else (
        echo [ERROR] Failed to delete server-cache folder
    )
) else (
    echo [INFO] server-cache folder not found - skipping
)

:: Delete server-cache-priv folder
if exist "%TARGET_DIR%\server-cache-priv" (
    echo Deleting server-cache-priv folder...
    rd /s /q "%TARGET_DIR%\server-cache-priv"
    if !errorlevel! equ 0 (
        echo [SUCCESS] server-cache-priv folder deleted
    ) else (
        echo [ERROR] Failed to delete server-cache-priv folder
    )
) else (
    echo [INFO] server-cache-priv folder not found - skipping
)

echo.
set /p "DELETE_NUI=Do you also want to delete the nui-storage folder? (Y/N): "
if /i "%DELETE_NUI%"=="Y" (
    echo.
    if exist "%TARGET_DIR%\nui-storage" (
        echo Deleting nui-storage folder...
        rd /s /q "%TARGET_DIR%\nui-storage"
        if !errorlevel! equ 0 (
            echo [SUCCESS] nui-storage folder deleted
        ) else (
            echo [ERROR] Failed to delete nui-storage folder
        )
    ) else (
        echo [INFO] nui-storage folder not found - skipping
    )
) else (
    echo.
    echo [INFO] nui-storage folder was not deleted
)

echo.
echo ========================================
echo Cleanup complete!
echo ========================================
echo.
pause
