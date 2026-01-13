@echo off
REM Setup script for NVIM Typing Kata Trainer (Windows Batch)
setlocal enabledelayedexpansion

echo ===============================================
echo    NVIM Typing Kata Trainer - Setup
echo ===============================================
echo.

REM Check if Python is installed
echo Checking for Python...
where python >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python
    goto :python_found
)

where python3 >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python3
    goto :python_found
)

echo [ERROR] Python not found!
echo Please install Python 3.10+ from https://www.python.org/
echo Make sure to check 'Add Python to PATH' during installation
pause
exit /b 1

:python_found
for /f "tokens=*" %%i in ('%PYTHON_CMD% --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [OK] %PYTHON_VERSION% found
echo.

REM Check if pip is available
echo Checking for pip...
%PYTHON_CMD% -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] pip not found!
    echo Please install pip for Python
    pause
    exit /b 1
)
echo [OK] pip found
echo.

REM Install dependencies
echo Installing Python dependencies...
%PYTHON_CMD% -m pip install -r requirements.txt --quiet
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies
    echo Try running manually: %PYTHON_CMD% -m pip install -r requirements.txt
    pause
    exit /b 1
)
echo [OK] Dependencies installed successfully
echo.

REM Create .env file if it doesn't exist
if exist .env (
    echo [WARNING] .env file already exists
    set /p OVERWRITE="Do you want to overwrite it? (y/N): "
    if /i not "!OVERWRITE!"=="y" (
        echo Skipping .env file creation...
        goto :skip_env
    )
    del .env
)

echo Creating .env file...
echo.

REM Detect Neovim config
echo Detecting Neovim configuration...
set NVIM_PATH=
if exist "%LOCALAPPDATA%\nvim" (
    if exist "%LOCALAPPDATA%\nvim\*.lua" (
        set NVIM_PATH=%LOCALAPPDATA%\nvim
        echo [OK] Found Neovim config at: !NVIM_PATH!
    )
)
if "!NVIM_PATH!"=="" (
    if exist "%APPDATA%\nvim" (
        if exist "%APPDATA%\nvim\*.lua" (
            set NVIM_PATH=%APPDATA%\nvim
            echo [OK] Found Neovim config at: !NVIM_PATH!
        )
    )
)
if "!NVIM_PATH!"=="" (
    if exist "%USERPROFILE%\.config\nvim" (
        if exist "%USERPROFILE%\.config\nvim\*.lua" (
            set NVIM_PATH=%USERPROFILE%\.config\nvim
            echo [OK] Found Neovim config at: !NVIM_PATH!
        )
    )
)
if "!NVIM_PATH!"=="" (
    echo [INFO] No Neovim config auto-detected
    set /p CUSTOM_NVIM="Enter Neovim config path (or press Enter to skip): "
    if not "!CUSTOM_NVIM!"=="" (
        if exist "!CUSTOM_NVIM!" (
            set NVIM_PATH=!CUSTOM_NVIM!
            echo [OK] Using custom path: !NVIM_PATH!
        ) else (
            echo [WARNING] Path does not exist, skipping
        )
    )
)

REM Detect vimrc
echo.
echo Detecting vimrc...
set VIMRC_PATH=
if exist "%USERPROFILE%\_vimrc" (
    set VIMRC_PATH=%USERPROFILE%\_vimrc
    echo [OK] Found vimrc at: !VIMRC_PATH!
)
if "!VIMRC_PATH!"=="" (
    if exist "%USERPROFILE%\.vimrc" (
        set VIMRC_PATH=%USERPROFILE%\.vimrc
        echo [OK] Found vimrc at: !VIMRC_PATH!
    )
)
if "!VIMRC_PATH!"=="" (
    if exist "%HOME%\_vimrc" (
        set VIMRC_PATH=%HOME%\_vimrc
        echo [OK] Found vimrc at: !VIMRC_PATH!
    )
)
if "!VIMRC_PATH!"=="" (
    echo [INFO] No vimrc auto-detected
    set /p CUSTOM_VIMRC="Enter vimrc path (or press Enter to skip): "
    if not "!CUSTOM_VIMRC!"=="" (
        if exist "!CUSTOM_VIMRC!" (
            set VIMRC_PATH=!CUSTOM_VIMRC!
            echo [OK] Using custom vimrc: !VIMRC_PATH!
        ) else (
            echo [WARNING] Path does not exist, skipping
        )
    )
)

REM API Key
echo.
echo You need a Claude API key from: https://console.anthropic.com/
echo.
set /p API_KEY="Enter your Claude API key (or press Enter to skip): "
echo.

if "!API_KEY!"=="" (
    echo [WARNING] No API key provided. Creating .env with placeholder...
    set API_KEY=your-api-key-here
)

REM Create .env file
(
echo # Claude API Configuration
echo CLAUDE_API_KEY=!API_KEY!
echo.
) > .env

if not "!NVIM_PATH!"=="" (
    (
    echo # Neovim Config Directory ^(auto-detected^)
    echo NVIM_CONFIG_DIR=!NVIM_PATH!
    echo.
    ) >> .env
) else (
    (
    echo # Neovim Config Directory ^(optional - will auto-detect if not specified^)
    echo # NVIM_CONFIG_DIR=
    echo.
    ) >> .env
)

if not "!VIMRC_PATH!"=="" (
    (
    echo # Vimrc Path ^(auto-detected^)
    echo VIMRC_PATH=!VIMRC_PATH!
    echo.
    ) >> .env
) else (
    (
    echo # Vimrc Path ^(optional - will auto-detect if not specified^)
    echo # VIMRC_PATH=
    echo.
    ) >> .env
)

(
echo # Optional: Where to save progress ^(default: ./progress^)
echo PROGRESS_DIR=progress
echo.
echo # Optional: AI feedback timing
echo # Options: after_each_task, end_of_session, none
echo AI_FEEDBACK_TIMING=end_of_session
echo.
echo # Optional: Exit sequence ^(default: jk^)
echo UNIVERSAL_EXIT_SEQUENCE=jk
echo.
echo # Optional: Theme ^(default: default^)
echo THEME=default
) >> .env

echo [OK] .env file created

if "!API_KEY!"=="your-api-key-here" (
    echo [WARNING] Remember to edit .env and add your actual API key!
)

if not "!NVIM_PATH!"=="" (
    echo.
    echo [OK] Custom Keybindings mode will use your configuration!
)
if not "!VIMRC_PATH!"=="" (
    if "!NVIM_PATH!"=="" (
        echo.
        echo [OK] Custom Keybindings mode will use your configuration!
    )
)

:skip_env
echo.

REM Create progress directory
echo Creating progress directory...
if not exist progress mkdir progress
echo [OK] Progress directory created
echo.

REM Setup complete
echo ===============================================
echo    Setup Complete!
echo ===============================================
echo.
echo [OK] All dependencies installed
echo [OK] Configuration file created
echo [OK] Progress directory ready
echo.
echo To start the application, run:
echo   %PYTHON_CMD% -m src.main
echo.

set /p RUN_NOW="Would you like to start the application now? (y/N): "
if /i "!RUN_NOW!"=="y" (
    echo.
    echo Starting NVIM Typing Kata Trainer...
    echo.
    %PYTHON_CMD% -m src.main
)

pause
