# Keyboard Shortcuts ⌨️

The NVIM Typing Kata Trainer is fully keyboard-driven for maximum efficiency, inspired by tools like k9s and vim itself!

## Main Menu

### Training Modes
| Key | Mode | Description |
|-----|------|-------------|
| `1` | 🎯 Custom Keybindings | Practice YOUR Neovim/Vim keybindings |
| `2` | 🐍 Snake Apple | Navigate with hjkl, w, b, e |
| `3` | 🔣 Symbol Training | Special characters and sequences |
| `4` | 💻 Coding Lessons | Type code with AI-generated lessons |
| `5` | 📝 Word Training | Vim word motions (w, b, e, W, B, E) |
| `6` | ⚡ Vim Motions | Complex vim operations with AI feedback |
| `7` | ⌨️  Comprehensive Keys | All keyboard keys including F1-F12 |

### Navigation & Options
| Key | Action | Description |
|-----|--------|-------------|
| `s` | Stats | View progress, XP, and statistics |
| `c` | Settings | Configure trainer options |
| `q` | Quit | Exit the application |
| `?` or `h` | Help | Show keyboard shortcuts help |

## In-Game Controls

### Universal Shortcuts
| Keys | Action | Description |
|------|--------|-------------|
| `jk` (quickly) | Exit Mode | Exit current training mode (0.5s window) |
| `Ctrl+C` | Force Quit | Emergency exit |
| `Esc` | Cancel | Cancel current action (context-dependent) |

### Mode-Specific Controls

#### Custom Keybindings Mode
- Type the keybinding sequence shown
- Supports leader keys, multi-key sequences
- Visual feedback for correct/incorrect keys

#### Snake Apple Mode
- `hjkl` - Basic vim navigation
- `w` `b` `e` - Word motions
- `0` `^` `$` - Line motions
- `gg` `G` - Jump to top/bottom

#### Symbol Training Mode
- Type symbols exactly as shown
- Supports multi-character sequences (==, ->, etc.)

#### Coding Lessons Mode
- Type code character-by-character
- `Tab` - Tab character
- `Enter` - Newline
- `Space` - Space

#### Word Training Mode
- `w` - Word forward
- `b` - Word back
- `e` - End of word
- `W` `B` `E` - WORD motions (space-separated)

#### Vim Motions Mode
- Complete vim commands as shown
- `Enter` - Submit when done
- Tracks efficiency vs optimal solution

#### Comprehensive Keys Mode
- Press any key shown
- Includes:
  - Letters: `a-z` `A-Z`
  - Numbers: `0-9`
  - Symbols: `!@#$%^&*()` etc.
  - Function keys: `F1-F12`
  - Navigation: Arrow keys, `Home`, `End`, `PageUp`, `PageDown`
  - Special: `Esc`, `Enter`, `Tab`, `Space`, `Backspace`, `Delete`

## Design Philosophy

The trainer follows these principles for keyboard navigation:

### 🎯 Zero Mouse Required
Every function accessible via keyboard. No need to reach for the mouse.

### ⚡ Fast Access
Single-key shortcuts for common actions. Numbers 1-7 for instant mode access.

### 🔄 Vim-Like
Familiar patterns for vim users:
- `hjkl` navigation where applicable
- `q` to quit
- `?` for help
- `jk` to escape

### 📊 Always Visible
Footer shows available shortcuts on every screen. No need to memorize everything.

## Tips & Tricks

### Quick Mode Switching
```
Main Menu → Press 1 → Custom Keybindings Mode
         → Press jk → Back to Main Menu
         → Press 4 → Coding Lessons Mode
```

### Stats Quick-Check
```
Any screen → Press s → View Stats → Press q → Back to where you were
```

### Help Anytime
```
Lost? → Press ? → See all shortcuts → Press any key to close
```

### Efficient Workflow
1. Start trainer: `python -m src.main`
2. Choose mode: Press `1-7`
3. Practice until satisfied
4. Exit with `jk`
5. Check stats: Press `s`
6. Try another mode: Press `1-7`
7. Quit when done: Press `q`

## Comparison with Other TUIs

### Like k9s
- Single-key navigation
- Minimal visual clutter
- Status bar at top
- Context hints at bottom
- Efficient screen usage

### Like vim
- Modal interface (different screens = different modes)
- `jk` to escape
- `?` for help
- `q` to quit
- Keyboard-first design

### Like htop
- Real-time statistics display
- Progress bars for visual feedback
- Color-coded information
- Clean, terminal-native look

## Accessibility

### For Vim Users
All controls feel natural. If you use vim, you'll feel right at home.

### For Terminal Users
Standard terminal controls work as expected. Ctrl+C always works.

### For Mouse Users
While keyboard shortcuts are recommended, you can still click on menu items if needed.

## Customization

Want different shortcuts? Edit the `BINDINGS` in `src/ui/screens/main_menu.py`:

```python
BINDINGS = [
    ("1", "launch_custom", "Custom Keybindings"),
    # Change "1" to your preferred key
    # ...
]
```

## Summary

**Main Menu:**
- `1-7` = Training modes
- `s` = Stats
- `c` = Settings
- `q` = Quit
- `?` = Help

**In-Game:**
- `jk` = Exit mode (universal)
- Mode-specific keys as shown

**Philosophy:**
- Keyboard-first
- Vim-inspired
- Fast and minimal
- Terminal-native

---

**Master the shortcuts, master vim faster!** ⚡
