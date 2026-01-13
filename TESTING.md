# Testing the Typing Kata Plugin

## Quick Test

Run Neovim with the test configuration:

```bash
nvim -u test_init.lua
```

This will:
1. Load the plugin from the current directory
2. Set up the plugin with default config
3. Automatically open the typing trainer after 1 second

## Manual Testing Steps

### Step 1: Open Neovim

```bash
cd C:\Users\lukey\workspaces\NVIM-Typing-Kata-Trainer
nvim -u test_init.lua
```

### Step 2: Check Plugin Loaded

You should see a notification: "Typing Kata Plugin Loaded!"

After 1 second, the main menu should appear automatically.

### Step 3: Test Main Menu

The menu should show:
- Your current rank (🌱 Recruit if new player)
- 7 game mode options (numbered 1-7)
- Stats option (s)
- Quit option (q)

Try pressing:
- `s` - Should show stats screen
- `ESC` or `q` - Should close the menu

### Step 4: Test Symbol Training

1. Press `3` to launch Symbol Training
2. You should see a symbol to type (e.g., `=>`)
3. Enter insert mode (if not automatic)
4. Type the symbol exactly
5. Watch your progress: Accuracy, Streak, XP
6. Complete a few symbols
7. Press `ESC` to exit
8. You should see a session summary notification

### Step 5: Test Word Typing

1. From menu, press `5` for Word Typing
2. You should see a word to type
3. Type each character correctly
4. Press Space or Enter to submit
5. Watch your WPM update in real-time
6. Complete a few words
7. Press `ESC` to exit

### Step 6: Test Snake Apple (Real Vim Motions!)

1. From menu, press `2` for Snake Apple
2. You should see a grid with:
   - Your cursor position (▸)
   - An apple (🍎)
3. Use vim motions to reach the apple:
   - Try `h`, `j`, `k`, `l` for basic movement
   - Try `w`, `e`, `b` for word-like jumps
   - Try `0`, `$` for line start/end
   - Try `5j` to move 5 lines down (REAL VIM!)
4. When you reach the apple, it should:
   - Award XP based on efficiency
   - Generate a new apple
5. Collect several apples
6. Press `q` or `ESC` to exit

### Step 7: Test Stats Screen

1. Press `s` in the main menu
2. You should see:
   - Your player name and rank
   - XP and progress to next rank
   - Total sessions and playtime
   - Per-mode statistics (for modes you've played)

### Step 8: Test Persistence

1. Play a game mode
2. Exit Neovim completely
3. Restart with `nvim -u test_init.lua`
4. Check stats - your progress should be saved!
5. Your save file is at: `~/.local/share/nvim/typing_kata/player_profile.json`

## Expected Behaviors

### Symbol Training
- ✅ Shows random symbols (single and combinations)
- ✅ Tracks accuracy per keystroke
- ✅ Increments streak on correct symbols
- ✅ Breaks streak on errors
- ✅ Awards XP based on accuracy and streak
- ✅ Session completes after 50 symbols

### Word Typing
- ✅ Shows common English words
- ✅ Calculates WPM in real-time
- ✅ Allows backspace to fix mistakes
- ✅ Shows next words preview
- ✅ Tracks accuracy and streak
- ✅ Session completes after 20 words

### Snake Apple
- ✅ Uses REAL Neovim cursor tracking
- ✅ ALL vim motions work (h/j/k/l, w/b/e, 0/$, gg/G, 5j, etc.)
- ✅ Calculates optimal path (Manhattan distance)
- ✅ Awards efficiency bonus
- ✅ Updates move count
- ✅ Session completes after 15 apples

## Troubleshooting

### Plugin doesn't load

Check if you're in the right directory:
```bash
pwd  # Should show the plugin directory
ls lua/typing_kata/init.lua  # Should exist
```

### "Failed to load ranks.json" error

Check if the file exists:
```bash
ls data/ranks.json
```

If missing, the ranks are in the repository at `data/ranks.json`.

### Cursor doesn't move in Snake Apple

Make sure you're in Normal mode (not Insert mode). Press `ESC` first, then use vim motions.

### No save file created

Check permissions on:
```bash
ls ~/.local/share/nvim/typing_kata/
# or on Windows:
ls %LOCALAPPDATA%\nvim-data\typing_kata\
```

## Debug Mode

To enable debug messages, edit `test_init.lua` and add:

```lua
require('typing_kata').setup({
  debug = true,
  -- ... other options
})
```

## Manual Commands

From within Neovim, you can also run:

- `:TypingKata` - Open main menu
- `:TypingKataStats` - View stats
- `:TypingKataRank` - Quick rank display
- `:lua print(vim.inspect(require('typing_kata').player))` - Inspect player data

## Success Criteria

✅ Plugin loads without errors
✅ Main menu displays correctly
✅ Can navigate menu with keyboard
✅ Symbol Training mode works
✅ Word Typing mode works
✅ Snake Apple mode uses REAL vim motions
✅ Stats screen shows data
✅ Progress is saved and persists
✅ Session summaries display on exit
✅ XP and ranks update correctly

Happy testing! 🎯
