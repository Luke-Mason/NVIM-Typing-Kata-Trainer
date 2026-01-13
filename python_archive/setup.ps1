# Setup script for NVIM Typing Kata Trainer (PowerShell)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   NVIM Typing Kata Trainer - Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Find Python
Write-Host "Checking for Python..." -ForegroundColor Yellow
$pythonCmd = $null

if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
}
elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCmd = "python3"
}
else {
    Write-Host "[ERROR] Python not found!" -ForegroundColor Red
    Write-Host "Install Python 3.10+ from https://www.python.org/" -ForegroundColor Yellow
    exit 1
}

$pythonVersion = & $pythonCmd --version 2>&1
Write-Host "[OK] $pythonVersion found" -ForegroundColor Green

# Check pip
Write-Host "Checking for pip..." -ForegroundColor Yellow
& $pythonCmd -m pip --version 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] pip not found!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] pip found" -ForegroundColor Green

# Install dependencies
Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Yellow
& $pythonCmd -m pip install -r requirements.txt --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
    Write-Host "Try: $pythonCmd -m pip install -r requirements.txt" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Dependencies installed" -ForegroundColor Green

# Handle .env file
Write-Host ""
$shouldCreate = $true

if (Test-Path .env) {
    Write-Host "[WARNING] .env already exists" -ForegroundColor Yellow
    $response = Read-Host "Overwrite? (y/N)"
    if ($response -match '^[Yy]$') {
        Remove-Item .env
    }
    else {
        $shouldCreate = $false
        Write-Host "Keeping existing .env file" -ForegroundColor Yellow
    }
}

if ($shouldCreate) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    Write-Host ""

    # Detect Neovim config
    Write-Host "Detecting Neovim configuration..." -ForegroundColor Yellow
    $nvimPath = $null
    $nvimPaths = @(
        "$env:LOCALAPPDATA\nvim",
        "$env:APPDATA\nvim",
        "$HOME\AppData\Local\nvim",
        "$HOME\.config\nvim"
    )

    foreach ($path in $nvimPaths) {
        if (Test-Path $path) {
            # Check if it has Lua files (indicates real config)
            $luaFiles = Get-ChildItem -Path $path -Filter "*.lua" -Recurse -ErrorAction SilentlyContinue
            if ($luaFiles.Count -gt 0) {
                $nvimPath = $path
                Write-Host "[OK] Found Neovim config at: $nvimPath" -ForegroundColor Green
                break
            }
        }
    }

    if (-not $nvimPath) {
        Write-Host "[INFO] No Neovim config auto-detected" -ForegroundColor Yellow
        $customPath = Read-Host "Enter Neovim config path (or press Enter to skip)"
        if (-not [string]::IsNullOrWhiteSpace($customPath)) {
            if (Test-Path $customPath) {
                $nvimPath = $customPath
                Write-Host "[OK] Using custom path: $nvimPath" -ForegroundColor Green
            }
            else {
                Write-Host "[WARNING] Path does not exist, skipping" -ForegroundColor Yellow
            }
        }
    }

    # Detect vimrc
    Write-Host ""
    Write-Host "Detecting vimrc..." -ForegroundColor Yellow
    $vimrcPath = $null
    $vimrcPaths = @(
        "$HOME\_vimrc",
        "$HOME\.vimrc",
        "$env:USERPROFILE\_vimrc",
        "$env:USERPROFILE\.vimrc"
    )

    foreach ($path in $vimrcPaths) {
        if (Test-Path $path) {
            $vimrcPath = $path
            Write-Host "[OK] Found vimrc at: $vimrcPath" -ForegroundColor Green
            break
        }
    }

    if (-not $vimrcPath) {
        Write-Host "[INFO] No vimrc auto-detected" -ForegroundColor Yellow
        $customVimrc = Read-Host "Enter vimrc path (or press Enter to skip)"
        if (-not [string]::IsNullOrWhiteSpace($customVimrc)) {
            if (Test-Path $customVimrc) {
                $vimrcPath = $customVimrc
                Write-Host "[OK] Using custom vimrc: $vimrcPath" -ForegroundColor Green
            }
            else {
                Write-Host "[WARNING] Path does not exist, skipping" -ForegroundColor Yellow
            }
        }
    }

    # API Key
    Write-Host ""
    Write-Host "Get your Claude API key from: https://console.anthropic.com/" -ForegroundColor Cyan
    Write-Host ""
    $apiKey = Read-Host "Enter your Claude API key (or press Enter to skip)"
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Host "[WARNING] No API key provided" -ForegroundColor Yellow
        $apiKey = "your-api-key-here"
    }

    # Build .env content
    $envContent = @"
# Claude API Configuration
CLAUDE_API_KEY=$apiKey

"@

    if ($nvimPath) {
        $envContent += @"
# Neovim Config Directory (auto-detected)
NVIM_CONFIG_DIR=$nvimPath

"@
    }
    else {
        $envContent += @"
# Neovim Config Directory (optional - will auto-detect if not specified)
# NVIM_CONFIG_DIR=

"@
    }

    if ($vimrcPath) {
        $envContent += @"
# Vimrc Path (auto-detected)
VIMRC_PATH=$vimrcPath

"@
    }
    else {
        $envContent += @"
# Vimrc Path (optional - will auto-detect if not specified)
# VIMRC_PATH=

"@
    }

    $envContent += @"
# Optional: Where to save progress (default: ./progress)
PROGRESS_DIR=progress

# Optional: AI feedback timing
# Options: after_each_task, end_of_session, none
AI_FEEDBACK_TIMING=end_of_session

# Optional: Exit sequence (default: jk)
UNIVERSAL_EXIT_SEQUENCE=jk

# Optional: Theme (default: default)
THEME=default
"@

    $envContent | Out-File -FilePath .env -Encoding utf8
    Write-Host "[OK] .env file created" -ForegroundColor Green

    if ($apiKey -eq "your-api-key-here") {
        Write-Host "[WARNING] Remember to add your actual API key to .env" -ForegroundColor Yellow
    }

    if ($nvimPath -or $vimrcPath) {
        Write-Host ""
        Write-Host "[OK] Custom Keybindings mode will use your configuration!" -ForegroundColor Green
    }
}

# Create progress directory
Write-Host ""
Write-Host "Creating progress directory..." -ForegroundColor Yellow
if (-not (Test-Path progress)) {
    New-Item -ItemType Directory -Path progress | Out-Null
}
Write-Host "[OK] Progress directory ready" -ForegroundColor Green

# Done
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Setup Complete!" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[OK] All dependencies installed" -ForegroundColor Green
Write-Host "[OK] Configuration file ready" -ForegroundColor Green
Write-Host "[OK] Progress directory created" -ForegroundColor Green
Write-Host ""
Write-Host "To start the application:" -ForegroundColor Cyan
Write-Host "  $pythonCmd -m src.main" -ForegroundColor Yellow
Write-Host ""

# Offer to run now
$runNow = Read-Host "Start the application now? (y/N)"
if ($runNow -match '^[Yy]$') {
    Write-Host ""
    Write-Host "Starting NVIM Typing Kata Trainer..." -ForegroundColor Cyan
    Write-Host ""
    & $pythonCmd -m src.main
}
