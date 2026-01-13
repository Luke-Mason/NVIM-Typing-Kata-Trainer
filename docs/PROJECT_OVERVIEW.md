# NVIM Typing Kata Trainer - Project Overview

## Vision & Goals

### Primary Goal
Create an engaging, gamified typing trainer specifically designed for Vim/Neovim users to practice:
- Vim motions and commands
- Touch typing speed (WPM)
- Special characters and symbols
- Custom keybindings
- Muscle memory for code editing

### Target Audience
- Vim/Neovim users wanting to improve editing speed
- Developers learning Vim motions
- Touch typists wanting vim-specific practice
- Users with custom keybindings wanting structured practice

### Core Philosophy
1. **Practice What You Actually Use** - Import user's real Neovim/Vim config
2. **Gamification** - XP, ranks, streaks, and progression to maintain motivation
3. **Variety** - Multiple game modes targeting different skills
4. **Immediate Feedback** - Real-time accuracy, WPM, and visual feedback
5. **Progressive Difficulty** - Start easy, scale to advanced challenges

## What It Achieved

### Successful Features
1. **8 Distinct Game Modes** - Each targeting different typing skills
2. **Custom Keybinding Support** - Parses user's Neovim/Vim config to create practice sessions
3. **100-Rank Progression System** - Military-themed ranks from Recruit to Vim Legend
4. **Comprehensive Stats Tracking** - Per-mode accuracy, WPM, streaks, and XP
5. **Cross-Platform Setup Scripts** - Auto-detects Neovim configs on Windows/Mac/Linux
6. **Session Persistence** - Saves progress to JSON, generates markdown reports
7. **Minimal TUI Interface** - k9s-inspired clean terminal interface
8. **Real-time Feedback** - Live WPM, accuracy, streak display during gameplay

### Technical Achievements
- Clean separation between game logic and UI (Textual TUI)
- Abstract base class pattern for game modes
- Async/await architecture for responsive input handling
- Comprehensive test suite (180+ tests)
- Vim config parser (vimrc + Lua) for custom keybindings
- Cross-platform keyboard input capture

## Project Structure

```
NVIM-Typing-Kata-Trainer/
├── src/
│   ├── game_modes/          # 8 game mode implementations
│   │   ├── base_mode.py     # Abstract base class
│   │   ├── word_typing.py   # Monkeytype-style word typing
│   │   ├── snake_apple.py   # Grid navigation with vim motions
│   │   ├── symbol_training.py
│   │   ├── coding_lessons.py
│   │   ├── custom_keybindings.py
│   │   ├── vim_motions.py
│   │   ├── comprehensive_keys.py
│   │   └── word_training.py # (Legacy vim motion version)
│   │
│   ├── ui/                  # Textual TUI screens
│   │   └── screens/
│   │       ├── main_menu.py
│   │       ├── game_screen.py
│   │       ├── stats.py
│   │       └── settings.py
│   │
│   ├── models/              # Data models
│   │   ├── player.py        # Player profile with stats
│   │   ├── session.py       # Per-session game state
│   │   └── progress.py      # Save/load player data
│   │
│   ├── core/                # Core systems
│   │   ├── config.py        # App configuration
│   │   ├── ranks.py         # Rank progression system
│   │   └── parsers/         # Vimrc & Lua config parsers
│   │
│   ├── input/               # Input handling
│   │   └── keyboard_handler.py  # pynput-based key capture
│   │
│   ├── utils/               # Utilities
│   │   └── stats_calculator.py  # XP formulas, bonuses
│   │
│   └── app.py               # Main application entry point
│
├── data/
│   └── ranks/
│       └── rank_definitions.json  # 100 rank definitions
│
├── tests/                   # Test suite (180+ tests)
│   ├── test_gameplay_integration.py
│   ├── test_system_e2e.py
│   └── test_*.py
│
├── progress/                # Generated player data (JSON)
└── setup scripts            # Cross-platform installation
```

## Key Technologies

### Python Stack
- **Python 3.11+** - Core language
- **Textual** - Terminal UI framework (TUI)
- **pynput** - Cross-platform keyboard input capture
- **pytest** - Testing framework
- **anthropic** - AI integration (optional, for coding lessons)

### Data Formats
- **JSON** - Player profiles, rank definitions, progress storage
- **Markdown** - Progress reports, documentation
- **Lua/VimScript** - Parsed for custom keybindings

## User Workflow

### Initial Setup
```bash
# Run setup script (detects Neovim config automatically)
./setup.sh  # or setup.ps1 (Windows)

# Manually set config path if auto-detection fails
# Prompts user for nvim config directory

# Install dependencies
pip install -r requirements.txt
```

### Gameplay Loop
```
1. Launch: python -m src.main
2. Main Menu: Select game mode (1-7)
3. Game Session: Practice (20 tasks per session)
4. Session Complete: View stats, earn XP
5. Return to Menu: Check rank progress
6. Repeat or Exit
```

### Progression Flow
```
Complete Tasks → Earn XP → Gain Ranks → Unlock Higher Challenges
     ↓              ↓           ↓              ↓
  Accuracy%    Track Stats   100 Ranks   Harder Content
```

## Design Principles

### 1. Modularity
- Each game mode is independent, implements BaseGameMode
- UI layer (Textual) separate from game logic
- Easy to add new game modes

### 2. Data-Driven
- Rank definitions in JSON (easy to tweak)
- Common word lists, symbol sets in code
- Player progress in JSON (portable)

### 3. User-Centric
- Auto-detect Neovim configs
- Practice YOUR keybindings, not generic ones
- Clear progress visualization

### 4. Progressive Enhancement
- Start with basic modes (Snake Apple)
- Advanced modes require more skill (Vim Motions, Coding)
- Rank system provides long-term goals

## Limitations & Challenges

### 1. Vim Simulation Issues
**Problem**: Can't properly simulate vim without running actual vim
- `5w` (move 5 words) doesn't work
- `d3w` (delete 3 words) doesn't work
- No command composition, text objects, registers

**Root Cause**: Simulating vim in Python is inadequate
**Solution**: Would need to embed actual Neovim or accept limitations

### 2. Game 5 Redesign
**Original Problem**: "Word Training" used vim motions (w, b, e)
- Could cheat by holding 'w'
- Not actual word typing

**User Feedback**: "I want it like monkeytype, actually typing words"
**Solution**: Complete redesign to character-by-character word typing

### 3. Python TUI Limitations
- Global keyboard listener (pynput) can be finicky
- Terminal UI less native than Neovim buffers
- Harder to integrate with user's Neovim workflow

## Success Metrics

### What Worked Well
1. ✅ **Custom Keybinding Parsing** - Users loved practicing their actual configs
2. ✅ **Snake Apple Mode** - Visual, fun, clear rules
3. ✅ **Word Typing Mode** (after redesign) - Proper WPM training
4. ✅ **Rank Progression** - Motivating, clear milestones
5. ✅ **Stats Tracking** - Detailed per-mode analytics
6. ✅ **Cross-Platform Setup** - Works on Windows/Mac/Linux

### What Didn't Work
1. ❌ **Vim Motion Simulation** - Incomplete, not authentic
2. ❌ **Original Game 5** - Too easy to game, unclear purpose
3. ❌ **Separate TUI App** - Not integrated into Neovim workflow
4. ❌ **AI Dependency** (optional) - Claude API not always needed

## User Feedback Summary

### Positive
- "Love practicing my actual keybindings!"
- "Snake Apple is fun and helps with hjkl"
- "Rank progression keeps me motivated"
- "Stats per mode are useful"

### Critical (Led to Improvements)
- "Game 5 - can just hold 'w' to win" → Fixed with redesign
- "5w doesn't work - not real vim" → Documented limitations
- "Want it like monkeytype" → Created Word Typing mode
- "Would be better as Neovim plugin" → This documentation!

## Ideal Future: Neovim Plugin

### Why a Neovim Plugin is Better
1. **Native Vim Motions** - Use actual Neovim, `5w` works!
2. **Buffer-Based Games** - Use buffers for display, no separate UI
3. **Integrated Workflow** - Practice without leaving Neovim
4. **Floating Windows** - Native menus, overlays
5. **Real Cursor** - Actual Neovim cursor for navigation games
6. **Extmarks & Highlights** - Rich visuals without external UI
7. **Autocommands** - React to real vim events (CursorMoved, etc.)

### What to Preserve
- All game mode concepts (8 modes)
- Progression system (XP, ranks, stats)
- Custom keybinding support
- Session tracking
- Clean architecture

### What to Replace
- Python → Lua
- Textual TUI → Neovim buffers/windows
- pynput → Neovim's native input
- Simulated vim → Real Neovim APIs

## Conclusion

This Python TUI typing trainer proved the concept and refined the game designs through user feedback. The core game modes, progression system, and architectural patterns are solid. The next evolution is a native Neovim plugin that leverages real vim, uses buffers for display, and integrates seamlessly into the user's workflow.

**This documentation serves as the specification for building that plugin from scratch in Lua.**
