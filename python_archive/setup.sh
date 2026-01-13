#!/bin/bash
# Setup script for NVIM Typing Kata Trainer
# Works on Linux, Mac, and Git Bash on Windows

set -e  # Exit on error

echo "╔═══════════════════════════════════════════════╗"
echo "║   NVIM Typing Kata Trainer - Setup           ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Python is installed
echo "Checking for Python..."
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}✗ Python not found!${NC}"
    echo "Please install Python 3.10+ from https://www.python.org/"
    exit 1
fi

# Determine Python command
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
else
    PYTHON_CMD="python"
    PIP_CMD="pip"
fi

# Check Python version
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo -e "${GREEN}✓ Python ${PYTHON_VERSION} found${NC}"

# Check if pip is available
if ! command -v $PIP_CMD &> /dev/null; then
    echo -e "${RED}✗ pip not found!${NC}"
    echo "Please install pip for Python"
    exit 1
fi
echo -e "${GREEN}✓ pip found${NC}"

# Install dependencies
echo ""
echo "Installing Python dependencies..."
if $PIP_CMD install -r requirements.txt --quiet; then
    echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
else
    echo -e "${RED}✗ Failed to install dependencies${NC}"
    echo "Try running manually: $PIP_CMD install -r requirements.txt"
    exit 1
fi

# Create .env file if it doesn't exist
echo ""
if [ -f .env ]; then
    echo -e "${YELLOW}⚠ .env file already exists${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping .env file creation..."
    else
        rm .env
        CREATE_ENV=true
    fi
else
    CREATE_ENV=true
fi

if [ "$CREATE_ENV" = true ]; then
    echo "Creating .env file..."
    echo ""

    # Detect Neovim config
    echo "Detecting Neovim configuration..."
    NVIM_PATH=""
    NVIM_PATHS=(
        "$HOME/.config/nvim"
        "$XDG_CONFIG_HOME/nvim"
        "$HOME/.nvim"
    )

    for path in "${NVIM_PATHS[@]}"; do
        if [ -d "$path" ]; then
            # Check if it has Lua files (indicates real config)
            if find "$path" -name "*.lua" -type f 2>/dev/null | grep -q .; then
                NVIM_PATH="$path"
                echo -e "${GREEN}✓ Found Neovim config at: $NVIM_PATH${NC}"
                break
            fi
        fi
    done

    if [ -z "$NVIM_PATH" ]; then
        echo -e "${YELLOW}ℹ No Neovim config auto-detected${NC}"
        read -p "Enter Neovim config path (or press Enter to skip): " CUSTOM_NVIM
        if [ -n "$CUSTOM_NVIM" ] && [ -d "$CUSTOM_NVIM" ]; then
            NVIM_PATH="$CUSTOM_NVIM"
            echo -e "${GREEN}✓ Using custom path: $NVIM_PATH${NC}"
        elif [ -n "$CUSTOM_NVIM" ]; then
            echo -e "${YELLOW}⚠ Path does not exist, skipping${NC}"
        fi
    fi

    # Detect vimrc
    echo ""
    echo "Detecting vimrc..."
    VIMRC_PATH=""
    VIMRC_PATHS=(
        "$HOME/.vimrc"
        "$HOME/.vim/vimrc"
    )

    for path in "${VIMRC_PATHS[@]}"; do
        if [ -f "$path" ]; then
            VIMRC_PATH="$path"
            echo -e "${GREEN}✓ Found vimrc at: $VIMRC_PATH${NC}"
            break
        fi
    done

    if [ -z "$VIMRC_PATH" ]; then
        echo -e "${YELLOW}ℹ No vimrc auto-detected${NC}"
        read -p "Enter vimrc path (or press Enter to skip): " CUSTOM_VIMRC
        if [ -n "$CUSTOM_VIMRC" ] && [ -f "$CUSTOM_VIMRC" ]; then
            VIMRC_PATH="$CUSTOM_VIMRC"
            echo -e "${GREEN}✓ Using custom vimrc: $VIMRC_PATH${NC}"
        elif [ -n "$CUSTOM_VIMRC" ]; then
            echo -e "${YELLOW}⚠ Path does not exist, skipping${NC}"
        fi
    fi

    # API Key
    echo ""
    echo -e "${YELLOW}You need a Claude API key from: https://console.anthropic.com/${NC}"
    echo ""
    read -p "Enter your Claude API key (or press Enter to skip): " API_KEY
    echo ""

    if [ -z "$API_KEY" ]; then
        echo -e "${YELLOW}⚠ No API key provided. Creating .env with placeholder...${NC}"
        API_KEY="your-api-key-here"
    fi

    # Create .env file
    cat > .env << EOF
# Claude API Configuration
CLAUDE_API_KEY=$API_KEY

EOF

    if [ -n "$NVIM_PATH" ]; then
        cat >> .env << EOF
# Neovim Config Directory (auto-detected)
NVIM_CONFIG_DIR=$NVIM_PATH

EOF
    else
        cat >> .env << EOF
# Neovim Config Directory (optional - will auto-detect if not specified)
# NVIM_CONFIG_DIR=

EOF
    fi

    if [ -n "$VIMRC_PATH" ]; then
        cat >> .env << EOF
# Vimrc Path (auto-detected)
VIMRC_PATH=$VIMRC_PATH

EOF
    else
        cat >> .env << EOF
# Vimrc Path (optional - will auto-detect if not specified)
# VIMRC_PATH=

EOF
    fi

    cat >> .env << EOF
# Optional: Where to save progress (default: ./progress)
PROGRESS_DIR=progress

# Optional: AI feedback timing
# Options: after_each_task, end_of_session, none
AI_FEEDBACK_TIMING=end_of_session

# Optional: Exit sequence (default: jk)
UNIVERSAL_EXIT_SEQUENCE=jk

# Optional: Theme (default: default)
THEME=default
EOF

    echo -e "${GREEN}✓ .env file created${NC}"

    if [ "$API_KEY" = "your-api-key-here" ]; then
        echo -e "${YELLOW}⚠ Remember to edit .env and add your actual API key!${NC}"
    fi

    if [ -n "$NVIM_PATH" ] || [ -n "$VIMRC_PATH" ]; then
        echo ""
        echo -e "${GREEN}✓ Custom Keybindings mode will use your configuration!${NC}"
    fi
fi

# Create progress directory
echo ""
echo "Creating progress directory..."
mkdir -p progress
echo -e "${GREEN}✓ Progress directory created${NC}"

# Setup complete
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║   Setup Complete!                             ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✓ All dependencies installed${NC}"
echo -e "${GREEN}✓ Configuration file created${NC}"
echo -e "${GREEN}✓ Progress directory ready${NC}"
echo ""
echo "To start the application, run:"
echo -e "${YELLOW}  $PYTHON_CMD -m src.main${NC}"
echo ""

# Ask if user wants to run now
read -p "Would you like to start the application now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting NVIM Typing Kata Trainer..."
    echo ""
    $PYTHON_CMD -m src.main
fi
