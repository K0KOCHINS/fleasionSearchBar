@echo off
setlocal EnableExtensions
title Fleasion + Search Bar

rem Double-click this file. The first run installs everything; later runs just start Fleasion.
rem Fleasion is made by the Fleasion team: https://github.com/fleasion/Fleasion

set "INSTALL_DIR=%USERPROFILE%\Documents\Fleasion-SearchBar"
set "PATCH_URL=https://raw.githubusercontent.com/K0KOCHINS/fleasionSearchBar/main/fleasion-config-search.patch"
set "PINNED_COMMIT=7f4c6c1"

rem Make tools installed during this run usable straight away
set "PATH=%USERPROFILE%\.local\bin;%ProgramFiles%\Git\cmd;%LOCALAPPDATA%\Programs\Git\cmd;%PATH%"

if exist "%INSTALL_DIR%\pyproject.toml" goto run

echo ================================================
echo   Fleasion + Search Bar - first-time setup
echo ================================================
echo This takes a few minutes. Keep this window open.
echo.

rem ---- Git ----
where git >nul 2>&1
if errorlevel 1 (
    echo [1/4] Installing Git...
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
)
where git >nul 2>&1
if errorlevel 1 (
    echo.
    echo Git could not be installed automatically.
    echo Install it from https://git-scm.com/download/win and then double-click this file again.
    pause
    exit /b 1
)
echo [1/4] Git is ready.

rem ---- uv ----
where uv >nul 2>&1
if errorlevel 1 (
    echo [2/4] Installing uv...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex"
)
where uv >nul 2>&1
if errorlevel 1 (
    echo.
    echo uv could not be installed automatically.
    echo Install it from https://docs.astral.sh/uv/ and then double-click this file again.
    pause
    exit /b 1
)
echo [2/4] uv is ready.

rem ---- Fleasion source ----
echo [3/4] Downloading Fleasion...
git clone --config core.autocrlf=false https://github.com/fleasion/Fleasion.git "%INSTALL_DIR%"
if errorlevel 1 (
    echo.
    echo Could not download Fleasion. Check your internet connection and try again.
    pause
    exit /b 1
)

rem ---- Search bar ----
echo [4/4] Adding the search bar...
cd /d "%INSTALL_DIR%"
call :apply_patch
if errorlevel 1 (
    echo.
    echo The search bar could not be added. Deleting the half-finished install...
    cd /d "%USERPROFILE%"
    rmdir /s /q "%INSTALL_DIR%"
    pause
    exit /b 1
)

echo.
echo Setup done! Starting Fleasion. The first start takes a minute or two.
echo.

:run
cd /d "%INSTALL_DIR%"
if /i "%~1"=="update" goto update
echo Starting Fleasion... (you can minimize this window, but don't close it)
uv run fleasion
if errorlevel 1 (
    echo.
    echo Fleasion closed with an error. If your normal Fleasion is open, exit it from the tray icon and try again.
    pause
)
exit /b 0

:update
echo Updating Fleasion and keeping the search bar...
git checkout -- . >nul 2>&1
git checkout main >nul 2>&1
git pull
call :apply_patch
if errorlevel 1 (
    pause
    exit /b 1
)
echo Update done. Starting Fleasion...
uv run fleasion
exit /b 0

:apply_patch
curl -fsSL -o search.patch "%PATCH_URL%"
if errorlevel 1 (
    echo Could not download the search bar patch.
    exit /b 1
)
git apply search.patch
if not errorlevel 1 exit /b 0
echo Latest Fleasion changed; using the version the search bar was made for...
git checkout -- . >nul 2>&1
git checkout %PINNED_COMMIT% >nul 2>&1
git apply search.patch
if errorlevel 1 (
    echo The search bar patch could not be applied.
    exit /b 1
)
exit /b 0
