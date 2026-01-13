# Game 5 Redesign: Word Typing Mode

## What Changed

Game 5 has been completely redesigned based on your feedback!

### Before (Word Training - Vim Motions)
```
❌ Problem: Navigate with vim motions (w, b, e, W, B, E)
❌ Problem: Could hold 'w' and always win
❌ Problem: Not actually typing words
❌ Problem: Misleading name - "Word Training"
```

### After (Word Typing - WPM Training)
```
✅ Solution: Type actual words character-by-character
✅ Solution: Works like monkeytype/typeracer
✅ Solution: Must type each word correctly
✅ Solution: Clear name - "Word Typing"
```

## How It Works Now

### Gameplay

1. **Start Game 5** - Press `5` from main menu
2. **See a word** - e.g., "the"
3. **Type it** - `t` `h` `e`
4. **Press Space** - Move to next word
5. **Continue** - Type 20 words per session

### Features

**Visual Feedback:**
- 🟢 Green = Correctly typed characters
- 🔴 Red = Wrong characters
- ⚪ Dim = Remaining characters

**Live Stats:**
- Current WPM (updates in real-time)
- Accuracy percentage
- Words completed (5/20)
- Next 3 words preview
- Best WPM (lifetime)

**Controls:**
- Type characters normally
- `Space` = Complete word and move to next
- `Backspace` = Correct mistakes
- `jk` = Exit mode

### Word List

Uses 200+ common English words from monkeytype:
- Common words: "the", "be", "to", "and", "have"
- Programming words: "function", "class", "return", "async"
- Mixed difficulty for natural typing practice

### Scoring

**XP Calculation:**
```python
Base XP: 50 (for completing 20-word session)

Bonuses:
- WPM Bonus: Higher WPM = more XP (40 WPM = 1.0x, 80 WPM = 2.0x)
- Accuracy Bonus: Perfect accuracy = 1.0x, 90% = 0.9x
- Streak Bonus: Consecutive correct words
```

### Example Session

```
Word Typing - WPM Training
━━━━━━━━━━━━━━━━━━━━━━━━

Progress: 5/20

Type this word:
  quick

Next: brown fox jumps

Current WPM: 45.3
Words Completed: 4
Errors: 2
Accuracy: 95.2%
XP Earned: 156

Type each word and press Space | Backspace to correct | 'jk' to exit
```

## Technical Changes

### New File
**`src/game_modes/word_typing.py`** - 340 lines
- Complete rewrite from scratch
- No vim motion logic
- Character-by-character typing validation
- Real-time WPM calculation
- Monkeytype-style word progression

### Updated Files
1. **`src/game_modes/__init__.py`**
   - Import `WordTypingMode` instead of `WordTrainingMode`

2. **`src/ui/screens/main_menu.py`**
   - Updated menu text: "📝 Word Typing (Type words - WPM like monkeytype)"
   - Updated action: `action_launch_words()` uses `WordTypingMode`
   - Updated help: "Word Typing (WPM Training)"

### Old File
**`src/game_modes/word_training.py`** - Kept for reference
- Can be removed or repurposed later
- Currently not used by the application

## Comparison

| Feature | Old (Word Training) | New (Word Typing) |
|---------|-------------------|------------------|
| **Core Mechanic** | Navigate with vim motions | Type words like monkeytype |
| **Input** | w, b, e, W, B, E | a-z, Space, Backspace |
| **Goal** | Reach target position | Type 20 words correctly |
| **Cheating** | ❌ Hold 'w' to win | ✅ Must type each character |
| **Like Monkeytype** | ❌ No | ✅ Yes! |
| **Tracks WPM** | ❌ No | ✅ Yes |
| **Visual Feedback** | Cursor position | Color-coded typing |
| **Purpose** | Practice vim motions | Improve typing speed |

## Why This Is Better

### Addresses Your Feedback

1. **"I could just hold down 'w' and win"**
   - ✅ Fixed! Must type each character correctly
   - Can't cheat by holding keys

2. **"Not actually typing words"**
   - ✅ Fixed! Now type real words character-by-character
   - Just like monkeytype

3. **"Should be like monkeytype"**
   - ✅ Fixed! Word-by-word progression
   - Space to move to next word
   - Live WPM tracking
   - Common word list

### Better Game Design

**Clear Purpose:**
- Old: Confusing mix of vim motions and word practice
- New: Clear focus on typing speed (WPM training)

**Skill Development:**
- Old: Practice vim motions (but poorly simulated)
- New: Improve typing speed and accuracy

**Engaging:**
- Old: Repetitive and easy to game
- New: Challenging and tracks progress

## What About Vim Motions?

Vim motion practice is still available in **Game 2 (Snake Apple)**:
- Visual grid-based navigation
- Uses hjkl, w, b, e, 0, $, gg, G
- Clear target (reach the apple)
- Actually fun and visual

For more on vim simulation limitations, see: `VIM_SIMULATION_LIMITATIONS.md`

## Testing

```bash
# Start the trainer
python -m src.main

# Press 5 for Word Typing
5

# Type a word
the[Space]

# Continue typing words
quick[Space]
brown[Space]
fox[Space]

# See your WPM increase!
```

## User Experience

### First Time User

```
> python -m src.main
[Press 5]

📝 Word Typing - WPM Training

Progress: 1/20

Type this word:
  the

Next: quick brown fox

Current WPM: 0.0
Words Completed: 0
Errors: 0

[Types: "the" + Space]

✅ Correct!

Type this word:
  quick

Current WPM: 52.3
...
```

### Experienced User

```
[Complete 20 words in ~45 seconds]

Session Complete!

Final Stats:
- WPM: 73.5 ⭐ New Best!
- Accuracy: 97.8%
- Words: 20/20
- Time: 45.2s
- XP Earned: +248

Best WPM: 73.5 (previous: 68.2)

Press any key to continue...
```

## Summary

✅ **Problem Solved** - Game 5 is now proper word typing
✅ **Like Monkeytype** - Character-by-character, word-by-word
✅ **No Cheating** - Must type correctly
✅ **Tracks WPM** - Real-time speed tracking
✅ **Clear Purpose** - Typing speed training

**Files Changed:**
- ✨ NEW: `src/game_modes/word_typing.py`
- 🔧 UPDATED: `src/game_modes/__init__.py`
- 🔧 UPDATED: `src/ui/screens/main_menu.py`
- 📝 NEW: `VIM_SIMULATION_LIMITATIONS.md`
- 📝 NEW: `GAME5_REDESIGN.md` (this file)

**Ready to test!** 🎯

---

**Thank you for the excellent feedback!** This is exactly what Game 5 should have been.
