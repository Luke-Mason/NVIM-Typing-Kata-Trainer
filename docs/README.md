# NVIM Typing Kata Trainer - Documentation

This directory contains complete documentation for the NVIM Typing Kata Trainer project, extracted from the Python TUI implementation to serve as the specification for a native Neovim plugin.

---

## What This Is

This documentation captures everything learned from building and user-testing a Python-based TUI typing trainer for Vim/Neovim users. It serves as:

1. **Specification** - Complete game mode designs, mechanics, and rules
2. **Architecture** - Proven patterns for game loops, progression, and stats
3. **Blueprint** - How to build it right as a Neovim plugin
4. **Lessons** - Critical insights from user feedback and iteration

---

## Documentation Files

### 📋 [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
High-level vision, goals, and what the Python TUI achieved.

**Read this to understand**:
- Why this project exists
- Target audience and use cases
- Core philosophy and principles
- Technical stack (Python version)
- Limitations and challenges
- Why a Neovim plugin is better

### 🎮 [GAME_MODES_SPECIFICATION.md](GAME_MODES_SPECIFICATION.md)
Complete specification of all 8 game modes with mechanics, scoring, and implementation notes.

**Game Modes**:
1. **Custom Keybindings** - Practice user's actual Neovim/Vim config
2. **Snake Apple** - Grid navigation with vim motions
3. **Symbol Training** - Special characters and programming symbols
4. **Coding Lessons** - Type real code with AI explanations
5. **Word Typing** - Monkeytype-style WPM training
6. **Vim Motions** - Complex vim operations with AI feedback
7. **Comprehensive Keys** - Practice all keyboard keys systematically

**For each mode**:
- Mechanics and rules
- Display format
- XP calculation
- Implementation notes
- What works and what doesn't

### 📊 [PROGRESSION_SYSTEM.md](PROGRESSION_SYSTEM.md)
Complete specification of XP, ranks, stats tracking, and persistence.

**Covers**:
- XP formulas with accuracy/speed/streak bonuses
- 100-rank military-themed progression (Recruit → Vim Legend)
- Per-mode stats (accuracy, WPM, streaks)
- JSON persistence schema
- Session tracking patterns
- Neovim plugin adaptations

### 🏗️ [NEOVIM_PLUGIN_ARCHITECTURE.md](NEOVIM_PLUGIN_ARCHITECTURE.md)
Proposed architecture for building the typing trainer as a native Neovim plugin.

**Includes**:
- Complete directory structure
- Lua module organization
- Base class pattern (BaseMode)
- Example implementations (Word Typing, Snake Apple)
- Menu system (floating windows)
- Real vim integration (how `5w` will work!)
- Installation and usage
- Implementation phases

### 🧠 [LESSONS_LEARNED.md](LESSONS_LEARNED.md)
Critical insights from building the Python version and user feedback.

**Key Lessons**:
1. Vim simulation is inadequate - use real vim!
2. Game 5 redesign - listen to users
3. Don't force vim where it doesn't fit
4. Custom keybinding support is killer feature
5. Progression system is motivating
6. Separate TUI app is wrong approach
7. Testing catches bugs users shouldn't find
8. Snake Apple is most engaging simple mode
9. AI integration is overrated
10. XP formula matters
11. Display matters - rich feedback is key
12. Cross-platform is hard
13. User feedback is gold
14. Architecture decisions that worked
15. The core game loop is solid

---

## How to Use This Documentation

### If You're Building the Neovim Plugin

**Start with**:
1. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - Understand the vision
2. [NEOVIM_PLUGIN_ARCHITECTURE.md](NEOVIM_PLUGIN_ARCHITECTURE.md) - Study the proposed architecture
3. [GAME_MODES_SPECIFICATION.md](GAME_MODES_SPECIFICATION.md) - Implement game modes one by one
4. [PROGRESSION_SYSTEM.md](PROGRESSION_SYSTEM.md) - Implement XP and ranks
5. [LESSONS_LEARNED.md](LESSONS_LEARNED.md) - Avoid known pitfalls

**Implementation Order** (easiest to hardest):
1. Core infrastructure (player save/load, ranks, XP)
2. Simple modes (Symbol Training, Comprehensive Keys)
3. WPM mode (Word Typing)
4. Visual mode (Snake Apple)
5. Config parser (Custom Keybindings)
6. Advanced modes (Coding Lessons, Vim Motions)

### If You're Just Curious

**Read**:
- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - What is this?
- [GAME_MODES_SPECIFICATION.md](GAME_MODES_SPECIFICATION.md) - What games exist?
- [LESSONS_LEARNED.md](LESSONS_LEARNED.md) - What went wrong and right?

---

## Key Concepts

### Game Modes
8 distinct training modes, each targeting different skills:
- **Typing Speed**: Word Typing (WPM)
- **Vim Motions**: Snake Apple, Vim Motions, Custom Keybindings
- **Special Characters**: Symbol Training
- **Code Typing**: Coding Lessons
- **Full Keyboard**: Comprehensive Keys

### Progression
- **XP System**: Earn XP from completed tasks with accuracy/speed/streak bonuses
- **100 Ranks**: Military-themed progression (Recruit → Vim Legend)
- **Per-Mode Stats**: Track accuracy, WPM, streaks per game mode
- **Persistence**: JSON files for save data

### Architecture
- **Base Class Pattern**: Abstract BaseMode class, each mode implements 5 methods
- **Game Loop**: Generate task → Wait input → Validate → Update → Render → Repeat
- **Session Tracking**: Track keystrokes, accuracy, streaks during gameplay
- **Display**: Buffer-based rendering with syntax highlighting

---

## Python TUI vs. Neovim Plugin

### Python TUI (Original Implementation)
**Pros**:
- ✅ Cross-platform (Windows/Mac/Linux)
- ✅ Rich terminal UI (Textual framework)
- ✅ Proven game mode designs
- ✅ Complete progression system

**Cons**:
- ❌ Separate app (workflow interruption)
- ❌ Simulated vim (can't do `5w`, `d3w`)
- ❌ Python dependency
- ❌ Not integrated with Neovim
- ❌ Global keyboard listener

### Neovim Plugin (Proposed)
**Pros**:
- ✅ Integrated workflow (never leave Neovim)
- ✅ Real vim motions (`5w`, `d3w` work!)
- ✅ Native Neovim buffers/windows
- ✅ Zero dependencies (pure Lua)
- ✅ Extmarks and highlights for rich visuals
- ✅ Floating windows for menus

**Cons**:
- ❌ Neovim-only (not standalone)
- ❌ Needs Neovim 0.9+ (modern API)

---

## Critical Design Decisions

### 1. Real Vim Integration
**Problem**: Python version simulated vim poorly (`5w` didn't work)
**Solution**: Neovim plugin uses actual vim, everything works natively

### 2. Buffer-Based Display
**Problem**: Textual TUI is separate from Neovim
**Solution**: Use Neovim buffers as game displays, integrate seamlessly

### 3. Game 5 Redesign
**Problem**: Original "Word Training" was vim motions, could cheat by holding 'w'
**Solution**: Complete redesign as character-by-character word typing (like monkeytype)

### 4. Custom Keybinding Support
**Killer Feature**: Parse user's `init.lua`/`.vimrc` to create personalized practice sessions

### 5. Progression System
**Motivation**: 100 ranks, XP bonuses, per-mode stats keep users engaged

---

## What Worked (Keep This)

✅ **All 8 game mode concepts** (with Game 5 redesign)
✅ **Progression system** (XP, ranks, stats)
✅ **Session tracking pattern**
✅ **XP calculation formulas**
✅ **Game loop architecture**
✅ **Custom keybinding parsing**
✅ **Per-mode analytics**

## What Didn't Work (Change This)

❌ **Python TUI** → Build as Neovim plugin
❌ **Vim simulation** → Use real Neovim
❌ **Global keyboard listener** → Use Neovim's input system
❌ **Separate app** → Integrate into workflow
❌ **AI dependency** → Make optional, use fallbacks

---

## Next Steps

### For Plugin Developers

1. **Setup**: Create new Neovim plugin repository
2. **Phase 1**: Core infrastructure (save/load, ranks, XP)
3. **Phase 2**: Simple modes (Symbol Training, Keys)
4. **Phase 3**: WPM mode (Word Typing)
5. **Phase 4**: Visual mode (Snake Apple with real vim!)
6. **Phase 5**: Advanced modes (Keybindings, Motions)
7. **Phase 6**: Polish (stats, statusline, help docs)

### For Users

The Python TUI version is archived but functional. To try it:
```bash
cd ../python_archive
python -m src.main
```

The Neovim plugin will be built using this documentation as the specification.

---

## File Organization

```
docs/
├── README.md                          # This file
├── PROJECT_OVERVIEW.md                # Vision and goals
├── GAME_MODES_SPECIFICATION.md        # All 8 game modes
├── PROGRESSION_SYSTEM.md              # XP, ranks, stats
├── NEOVIM_PLUGIN_ARCHITECTURE.md      # How to build the plugin
└── LESSONS_LEARNED.md                 # Critical insights
```

---

## Summary

This documentation represents the complete knowledge distilled from building and user-testing a Python TUI typing trainer. The core concepts, game designs, and progression system are solid. The implementation just needs to move from Python to Lua and from Textual to native Neovim.

**The Python version was the prototype.**
**The Neovim plugin will be the real product.**

Everything you need to build it is documented here.

---

## Questions?

This documentation should be comprehensive enough to build the Neovim plugin from scratch. If you find gaps or need clarification, consider:

1. Reviewing the Python implementation (archived)
2. Testing game modes to understand mechanics
3. Reading user feedback (FEEDBACK_RESPONSE.md, VIM_SIMULATION_LIMITATIONS.md)

---

**Ready to build the plugin? Start with [NEOVIM_PLUGIN_ARCHITECTURE.md](NEOVIM_PLUGIN_ARCHITECTURE.md)!**
