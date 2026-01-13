# Setup Guide

This guide will help you get NVIM Typing Kata Trainer up and running quickly.

## Prerequisites

Before you begin, make sure you have:

1. **Python 3.10 or higher**
   - Check: `python --version` or `python3 --version`
   - Download: https://www.python.org/downloads/
   - Windows: Make sure to check "Add Python to PATH" during installation

2. **Git** (optional, for cloning)
   - Check: `git --version`
   - Download: https://git-scm.com/

3. **Claude API Key**
   - Get one from: https://console.anthropic.com/
   - Sign up for an Anthropic account if you don't have one
   - Create an API key in your account settings

4. **Terminal**
   - Windows: Windows Terminal (recommended) or PowerShell 7+
   - Mac/Linux: Any modern terminal

## Automated Setup

We provide automated setup scripts for all platforms!

### Windows PowerShell (Recommended)

```powershell
# Navigate to the project directory
cd NVIM-Typing-Kata-Trainer

# Run the setup script
powershell -ExecutionPolicy Bypass -File setup.ps1
```

The script will:
- ✓ Check for Python and pip
- ✓ Install all dependencies
- ✓ Prompt you for your Claude API key
- ✓ Create the .env configuration file
- ✓ Set up the progress directory
- ✓ Optionally launch the application

### Windows Command Prompt

```cmd
cd NVIM-Typing-Kata-Trainer
setup.bat
```

### Mac / Linux / Git Bash on Windows

```bash
cd NVIM-Typing-Kata-Trainer
chmod +x setup.sh
./setup.sh
```

## What the Setup Scripts Do

1. **Check Python Installation**
   - Verifies Python 3.10+ is installed
   - Checks that pip is available

2. **Install Dependencies**
   - Installs all required Python packages from requirements.txt
   - Includes: textual, pynput, anthropic, python-dotenv, pydantic

3. **Create .env File**
   - Prompts you for your Claude API key
   - Creates a .env file with your configuration
   - Sets sensible defaults for other settings

4. **Create Progress Directory**
   - Sets up the directory where your progress will be saved
   - This is where player_profile.json and progress_report.md will live

5. **Launch Application** (optional)
   - Asks if you want to start the application immediately

## Manual Setup

If you prefer to set everything up manually:

### Step 1: Install Dependencies

```bash
pip install -r requirements.txt
```

Or on some systems:
```bash
pip3 install -r requirements.txt
```

### Step 2: Create .env File

Copy the example file:
```bash
# Windows
copy .env.example .env

# Mac/Linux
cp .env.example .env
```

Edit .env and add your API key:
```bash
# Windows
notepad .env

# Mac/Linux
nano .env
```

Add your key:
```
CLAUDE_API_KEY=sk-ant-api03-your-actual-key-here
```

### Step 3: Create Progress Directory

```bash
mkdir progress
```

### Step 4: Run the Application

```bash
python -m src.main
```

## Configuration Options

Your `.env` file supports these options:

### Required
```env
# Your Claude API key (required for AI features)
CLAUDE_API_KEY=sk-ant-api03-your-key-here
```

### Optional
```env
# Path to your vimrc (auto-detected if not specified)
VIMRC_PATH=C:\Users\YourName\_vimrc

# Where to save progress (default: ./progress)
PROGRESS_DIR=progress

# AI feedback timing (default: end_of_session)
# Options: after_each_task, end_of_session, none
AI_FEEDBACK_TIMING=end_of_session

# Exit sequence (default: jk)
# Press these keys quickly (within 0.5s) to exit any game mode
UNIVERSAL_EXIT_SEQUENCE=jk

# Theme (default: default)
THEME=default
```

## Troubleshooting

### "Python not found"

Make sure Python is installed and in your PATH:
- Windows: Reinstall Python and check "Add Python to PATH"
- Mac: Install via Homebrew: `brew install python`
- Linux: Install via package manager: `sudo apt install python3`

### "pip not found"

Install pip:
```bash
python -m ensurepip --upgrade
```

### "Permission denied" on setup.sh (Mac/Linux)

Make the script executable:
```bash
chmod +x setup.sh
```

### "Execution policy" error (PowerShell)

Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Or use the bypass flag:
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

### API Key Not Working

- Make sure there are no spaces before or after your API key
- Verify the key is correct in your Anthropic console
- Check that the .env file is in the project root directory
- Don't commit your .env file to Git (it's in .gitignore)

### Dependencies Won't Install

Try installing with verbose output to see errors:
```bash
pip install -r requirements.txt --verbose
```

If specific packages fail, install them individually:
```bash
pip install textual
pip install pynput
pip install anthropic
pip install python-dotenv
pip install pydantic
```

### "No module named 'src'"

Make sure you're running from the project root directory:
```bash
cd NVIM-Typing-Kata-Trainer
python -m src.main
```

## First Run

After setup, your first run should look like this:

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         NVIM TYPING KATA TRAINER                          ║
║         Master Vim Through Gamified Training              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Loading configuration...
✓ Configuration loaded successfully
✓ API Key: Set
⚠ Vimrc: Not found (AI feedback will be limited)
✓ Progress Directory: progress
✓ Exit Sequence: jk
✓ AI Feedback: end_of_session

Created new player: Player
```

You should see the main menu with:
- Your rank (starting at 🎖️ Recruit)
- XP progress (starting at 0)
- 6 game mode buttons
- Stats, Settings, and Exit options

## Running the Application

After initial setup, you can run the application anytime with:

```bash
cd NVIM-Typing-Kata-Trainer
python -m src.main
```

Or create an alias:

**Bash/Zsh (~/.bashrc or ~/.zshrc):**
```bash
alias vim-trainer='cd ~/NVIM-Typing-Kata-Trainer && python -m src.main'
```

**PowerShell ($PROFILE):**
```powershell
function Start-VimTrainer { cd C:\path\to\NVIM-Typing-Kata-Trainer; python -m src.main }
Set-Alias vim-trainer Start-VimTrainer
```

Then just run:
```bash
vim-trainer
```

## Getting Help

- Check the main [README.md](README.md) for usage instructions
- View your configuration in the Settings screen
- See your progress in the Stats screen
- Press `q` or `Ctrl+C` to quit at the main menu
- Press `jk` quickly to exit any game mode

## What's Next?

Once setup is complete:

1. **Start Training**: Select "⌨️ Comprehensive Keys" mode
2. **Practice**: Press the displayed keys as fast as you can
3. **Track Progress**: Check the Stats screen to see your improvement
4. **Rank Up**: Earn XP to progress through 100 ranks
5. **Have Fun**: Become a vim master!

Good luck on your journey from 🎖️ Recruit to 🔥👑🔥 Ultimate Vim God!
