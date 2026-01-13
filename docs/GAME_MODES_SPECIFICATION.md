# Game Modes Specification

Complete specification of all 8 game modes, their mechanics, and design rationale.

---

## Game Mode 1: Custom Keybindings

**Icon**: 🎯
**Purpose**: Practice user's actual Neovim/Vim keybindings
**Difficulty**: Variable (depends on user's config)

### Mechanics
1. **Keybinding Source**: Parses user's `init.lua`, `init.vim`, or `.vimrc`
2. **Task Format**: Shows a keybinding description → User must type the keys
3. **Example Task**:
   ```
   Keybinding: <leader>ff
   Description: Find files with telescope

   Type the keys: [waiting for input]
   ```
4. **Validation**: Exact keystroke sequence match (including modifiers)
5. **Session**: 20 keybindings per session

### Display Format
```
🎯 Custom Keybindings Training

Keybinding Practice (15/20)

Command: <leader>ff
Description: Find files with telescope

Type this keybinding...

Accuracy: 93.3%
Streak: 5
XP this session: 127
```

### XP Calculation
- Base: 15 XP per keybinding
- Accuracy bonus: 0-10 XP
- Streak bonus: 0-15 XP (caps at 30 streak)
- Speed bonus: 0-5 XP (faster = more XP)

### Implementation Notes
- **Parser**: `src/core/parsers/lua_parser.py` and `vimrc_parser.py`
- **Keybinding Storage**: Extracts key-description pairs
- **Key Sequence Matching**: Handles `<leader>`, `<C-x>`, `<M-y>`, etc.
- **Fallback**: If no config found, uses common vim defaults

### Why It Works
- **Personalized**: Practices what the user actually uses
- **Real-world**: Builds muscle memory for daily editing
- **Varied**: Each user has different keybindings

---

## Game Mode 2: Snake Apple

**Icon**: 🐍
**Purpose**: Visual vim motion practice with navigation game
**Difficulty**: Easy to Medium

### Mechanics
1. **Grid**: 20x40 character grid
2. **Cursor**: Your position (▸)
3. **Target**: Apple emoji (🍎) at random location
4. **Goal**: Navigate cursor to apple using vim motions
5. **Allowed Motions**:
   - `h`, `j`, `k`, `l` - Character movement
   - `w`, `b`, `e` - Word movement
   - `0`, `$` - Line start/end
   - `gg`, `G` - Buffer start/end
6. **Scoring**: Fewer moves = more XP

### Display Format
```
🐍 Snake Apple - Vim Navigation

........................................
......▸.................................
........................................
......................🍎................
........................................
[20x40 grid]

Moves: 7
Best Moves: 5
Target Position: (3, 22)

Available: hjkl, w/b/e, 0/$, gg/G
```

### XP Calculation
- Base: 10 XP per apple
- Efficiency bonus: (optimal_moves / actual_moves) * 20 XP
- Speed bonus: 0-5 XP (faster completion)
- Streak bonus: 0-15 XP

### Implementation Notes
- **Grid Representation**: 2D list of characters
- **Cursor Tracking**: Row/col coordinates
- **Motion Implementation**: Simulates vim motions on grid
- **Apple Placement**: Random empty cell
- **Optimal Path**: A* pathfinding for efficiency calculation

### Why It Works
- **Visual**: Clear feedback on cursor position
- **Gamified**: Fun "collect the apple" mechanic
- **Progressive**: Random placement creates variety
- **Motion Practice**: Encourages using efficient motions (w vs. l)

### Known Limitations
- No count multipliers (`5w` doesn't work)
- Simplified word boundaries
- But: Good enough for basic motion practice!

---

## Game Mode 3: Symbol Training

**Icon**: 🔣
**Purpose**: Practice special characters and symbols
**Difficulty**: Easy to Medium

### Mechanics
1. **Symbol Categories**:
   - **Brackets**: `()`, `[]`, `{}`, `<>`
   - **Operators**: `+`, `-`, `*`, `/`, `=`, `==`, `!=`, `<=`, `>=`
   - **Special**: `;`, `:`, `,`, `.`, `?`, `!`, `@`, `#`, `$`, `%`, `^`, `&`
   - **Quotes**: `'`, `"`, `` ` ``
   - **Combinations**: `->`, `=>`, `::`, `&&`, `||`, `++`, `--`
2. **Task**: Show symbol → User types it exactly
3. **Session**: 50 symbols per session
4. **Progressive**: Starts with single chars, adds combinations

### Display Format
```
🔣 Symbol Training

Type this symbol:
  =>

Progress: 23/50
Accuracy: 96.0%
Current Streak: 12
XP Earned: 234

Press the exact keys shown
```

### XP Calculation
- Base: 5 XP per symbol
- Accuracy bonus: 0-5 XP
- Streak bonus: 0-10 XP
- Combo bonus: +5 XP for multi-char symbols

### Implementation Notes
- **Symbol Lists**: Organized by category in code
- **Difficulty Progression**: Mix of easy and hard symbols
- **Common in Code**: Focuses on programming symbols

### Why It Works
- **Practical**: Symbols used daily in coding
- **Quick**: Fast-paced, immediate feedback
- **Muscle Memory**: Builds automatic symbol recall

---

## Game Mode 4: Coding Lessons (AI-Powered)

**Icon**: 💻
**Purpose**: Type real code character-by-character with AI explanations
**Difficulty**: Medium to Hard

### Mechanics
1. **AI Generation**: Uses Claude API to generate code lessons
2. **Languages**: Python, JavaScript, Rust, Go, TypeScript
3. **Lesson Format**:
   - Code snippet (5-15 lines)
   - AI explanation of what it does
   - Type character-by-character
4. **Validation**: Exact character match (including whitespace)
5. **Session**: 5-10 code snippets per session

### Display Format
```
💻 Coding Lessons - Python

Lesson 3/5

Type this code:

def calculate_average(numbers):
    return sum(numbers) / len(numbers)

[Your typing: def calcul_]

Current WPM: 45.2
Accuracy: 98.1%
Lines: 1/2

AI Hint: This function calculates the mean of a list
```

### XP Calculation
- Base: 50 XP per code snippet
- WPM bonus: 0-30 XP (40+ WPM = bonus)
- Accuracy bonus: 0-20 XP (>95% = max)
- Complexity bonus: Harder code = more XP

### Implementation Notes
- **AI Integration**: Optional, uses Claude API
- **Fallback**: Built-in code snippets if no API
- **Syntax Highlighting**: Visual feedback on typing
- **Language Selection**: User chooses or random

### Why It Works
- **Real Code**: Practice actual programming patterns
- **Context**: AI explanations help understanding
- **WPM Training**: Like monkeytype but for code
- **Variety**: Infinite content via AI

### Requirements
- Anthropic API key (optional)
- Fallback mode works without API

---

## Game Mode 5: Word Typing

**Icon**: 📝
**Purpose**: Monkeytype-style WPM training
**Difficulty**: Easy to Hard (scales with speed)

### Mechanics
1. **Word List**: 200+ common English words
2. **Task**: Type each word character-by-character
3. **Completion**: Press `Space` to move to next word
4. **Backspace**: Fix mistakes before submitting
5. **Session**: 20 words per session
6. **Real-time WPM**: Updates as you type

### Display Format
```
📝 Word Typing - WPM Training

Progress: 8/20

Type this word:
  quick

[You typed: qui_]

Next words: brown, fox, jumps

Current WPM: 52.3
Accuracy: 97.5%
Errors: 2
Best WPM: 68.1
```

### XP Calculation
- Base: 50 XP per session (20 words)
- WPM bonus: (WPM / 40) * 50 XP (scales with speed)
- Accuracy bonus: accuracy% * 50 XP
- Streak bonus: 0-15 XP

### Implementation Notes
- **Word Source**: Common words from monkeytype
- **WPM Formula**: (characters typed / time) * 12 (assumes 5 chars/word)
- **Char-by-char validation**: Can't cheat by holding keys
- **Space completion**: Prevents accidental skips

### Why It Works
- **Like Monkeytype**: Familiar to typists
- **Immediate WPM**: Real-time speed feedback
- **No Cheating**: Must type every character
- **Progressive**: Tracks best WPM, encourages improvement

### History
- **V1 (Original)**: Used vim word motions (w, b, e) - could cheat
- **V2 (Current)**: Complete redesign after user feedback
- **Lesson**: Listen to users, don't force vim where it doesn't fit!

---

## Game Mode 6: Vim Motions (AI-Powered)

**Icon**: ⚡
**Purpose**: Complex vim operations with AI feedback
**Difficulty**: Hard to Expert

### Mechanics
1. **AI Generation**: Claude generates vim editing tasks
2. **Task Types**:
   - Navigation challenges
   - Text manipulation
   - Search and replace
   - Complex combinations
3. **Recording**: Captures keystroke sequence
4. **AI Feedback**: Evaluates efficiency of solution
5. **Session**: 10-15 tasks per session

### Display Format
```
⚡ Vim Motions - Expert Training

Task 5/10

Challenge:
"Delete the word under the cursor and insert 'function'"

[Buffer shown here with cursor]

Your keystrokes: [recorded in real-time]

AI Feedback: "Good! Using 'ciw' is efficient. You could
also use 'diw' then 'i' for the same result."

Efficiency: 85%
```

### XP Calculation
- Base: 30 XP per task
- Efficiency bonus: 0-30 XP (AI evaluates)
- Speed bonus: 0-10 XP
- Complexity bonus: Harder tasks = more XP

### Implementation Notes
- **AI Required**: Needs Claude API for task generation
- **Keystroke Recording**: Tracks all vim commands
- **Evaluation**: AI analyzes efficiency
- **Learning**: Provides tips for improvement

### Known Limitations
- **Vim Simulation**: Can't execute `5w`, `d3w`, etc.
- **Root Cause**: Simulating vim in Python is inadequate
- **Solution in Plugin**: Use actual Neovim, problem solved!

### Why It Works (When It Works)
- **Challenging**: Tests vim knowledge
- **AI Feedback**: Learns better solutions
- **Variety**: Infinite tasks via AI
- **Progressive**: Adapts difficulty

### Why It's Limited
- ❌ No count multipliers
- ❌ No command composition
- ❌ Not real vim
- ✅ **Fixed in Neovim plugin**: Will use real vim!

---

## Game Mode 7: Comprehensive Keys

**Icon**: ⌨️
**Purpose**: Practice all keyboard keys systematically
**Difficulty**: Easy to Medium

### Mechanics
1. **Key Categories**:
   - Letters: a-z, A-Z
   - Numbers: 0-9
   - Function keys: F1-F12
   - Special: Enter, Tab, Escape, Backspace
   - Arrows: ↑↓←→
   - Modifiers: Ctrl, Shift, Alt combos
2. **Task**: Display key name → User presses it
3. **Session**: 30 keys per session (mixed categories)
4. **Progressive**: Starts with letters, adds special keys

### Display Format
```
⌨️ Comprehensive Keys Training

Press this key:
  [F5]

Key Category: Function Keys
Progress: 18/30
Accuracy: 96.7%
Avg Reaction Time: 0.42s

Next keys: Tab, Ctrl+S, Escape
```

### XP Calculation
- Base: 5 XP per key
- Speed bonus: 0-5 XP (faster reaction)
- Accuracy bonus: 0-5 XP
- Category completion bonus: +20 XP per category

### Implementation Notes
- **Key Detection**: Uses pynput's key codes
- **Reaction Time**: Measures press speed
- **Category Tracking**: Ensures full coverage

### Why It Works
- **Comprehensive**: Covers all keys
- **Systematic**: No key left behind
- **Muscle Memory**: Builds keyboard familiarity
- **Speed Focus**: Tracks reaction time

---

## Game Mode 8: Word Training (Legacy)

**Icon**: 📝 (legacy)
**Status**: Replaced by Word Typing (Mode 5)
**Purpose**: Original vim word motion trainer

### Original Mechanics (Deprecated)
- Navigate text using `w`, `b`, `e`, `W`, `B`, `E`
- Reach target position
- Count moves for efficiency

### Why It Was Replaced
- **User Feedback**: "Can hold 'w' to always win"
- **Not Real Typing**: Just motion practice
- **Confusing**: Called "word training" but not typing words
- **Solution**: Complete redesign as Mode 5 (Word Typing)

### Kept For
- Reference implementation
- Historical comparison
- May be useful for Snake Apple evolution

---

## Summary: Game Mode Design Principles

### What Makes a Good Mode
1. ✅ **Clear Goal**: User knows what to do
2. ✅ **Immediate Feedback**: Visual, real-time updates
3. ✅ **Progressive Difficulty**: Starts easy, scales up
4. ✅ **No Cheating**: Can't game the system
5. ✅ **Practical**: Teaches real skills
6. ✅ **Varied**: Different challenges per session

### What Doesn't Work
1. ❌ **Too Easy**: Can be gamed (old Word Training)
2. ❌ **Unclear Purpose**: Confusing mechanics
3. ❌ **Simulated Vim**: Can't replicate real vim behavior
4. ❌ **Boring Repetition**: Same task over and over

### For Neovim Plugin
- **Keep**: All mode concepts, mechanics, XP formulas
- **Improve**: Use real vim for Vim Motions mode
- **Enhance**: Buffer-based display, extmarks, highlights
- **Integrate**: Seamless Neovim workflow

---

## Game Mode Comparison Table

| Mode | Difficulty | Session Length | AI Required | Vim Motions | Best For |
|------|------------|----------------|-------------|-------------|----------|
| **Custom Keybindings** | Variable | 20 tasks | No | No | Practicing your config |
| **Snake Apple** | Easy-Med | 15-20 apples | No | Yes (basic) | Learning vim navigation |
| **Symbol Training** | Easy-Med | 50 symbols | No | No | Special character speed |
| **Coding Lessons** | Med-Hard | 5-10 snippets | Optional | No | Code typing (WPM) |
| **Word Typing** | Easy-Hard | 20 words | No | No | Pure WPM training |
| **Vim Motions** | Hard-Expert | 10-15 tasks | Yes | Yes (limited) | Advanced vim commands |
| **Comprehensive Keys** | Easy-Med | 30 keys | No | No | Full keyboard coverage |

---

## Implementation Checklist for Neovim Plugin

For each game mode, implement:
- [ ] Lua module with mode logic
- [ ] Buffer display function
- [ ] Input handler (keymaps)
- [ ] XP calculation
- [ ] Session tracking
- [ ] Display update loop
- [ ] Completion detection
- [ ] Stats recording

**Priority Order** (easiest to hardest):
1. Symbol Training (simplest)
2. Comprehensive Keys (simple)
3. Word Typing (moderate, WPM tracking)
4. Snake Apple (moderate, grid display)
5. Custom Keybindings (needs config parser)
6. Coding Lessons (needs AI or fallback)
7. Vim Motions (needs AI + real vim integration)
