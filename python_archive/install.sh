#!/bin/bash
# Quick install script for NVIM Typing Kata Trainer
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/NVIM-Typing-Kata-Trainer/main/install.sh | bash
# Or with a specific directory: curl -fsSL ... | bash -s /path/to/install

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║   NVIM Typing Kata Trainer - Quick Install   ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Determine install directory
if [ -n "$1" ]; then
    INSTALL_DIR="$1"
else
    INSTALL_DIR="$HOME/nvim-typing-kata-trainer"
fi

echo -e "${YELLOW}Installation directory: ${INSTALL_DIR}${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git not found!${NC}"
    echo "Please install git first: https://git-scm.com/"
    exit 1
fi
echo -e "${GREEN}✓ Git found${NC}"

# Clone repository
echo ""
echo -e "${YELLOW}Cloning repository...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠ Directory already exists: ${INSTALL_DIR}${NC}"
    read -p "Remove and re-clone? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
    else
        echo "Using existing directory..."
        cd "$INSTALL_DIR"
        git pull
    fi
else
    # TODO: Update this URL to your actual GitHub repository
    # git clone https://github.com/YOUR_USERNAME/NVIM-Typing-Kata-Trainer.git "$INSTALL_DIR"
    echo -e "${RED}✗ Repository URL not configured yet${NC}"
    echo -e "${YELLOW}To use this script, update the git clone URL in install.sh${NC}"
    echo ""
    echo -e "${CYAN}For now, manually clone the repository:${NC}"
    echo "  git clone <your-repo-url> $INSTALL_DIR"
    echo "  cd $INSTALL_DIR"
    echo "  ./setup.sh"
    exit 1
fi

cd "$INSTALL_DIR"
echo -e "${GREEN}✓ Repository ready${NC}"

# Run setup script
echo ""
echo -e "${YELLOW}Running setup script...${NC}"
echo ""
chmod +x setup.sh
./setup.sh

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Installation Complete!                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Application installed to: ${INSTALL_DIR}${NC}"
echo ""
echo -e "${YELLOW}To run the application:${NC}"
echo "  cd $INSTALL_DIR"
echo "  python -m src.main"
echo ""
echo -e "${YELLOW}Or create an alias in your ~/.bashrc or ~/.zshrc:${NC}"
echo "  alias vim-trainer='cd $INSTALL_DIR && python -m src.main'"
echo ""
