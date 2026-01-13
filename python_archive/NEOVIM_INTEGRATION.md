# Neovim Configuration Integration 🎯

## Overview

The NVIM Typing Kata Trainer now **automatically detects and parses your Neovim Lua configuration** to provide **personalized training** based on YOUR actual keybindings, plugins, and setup!

## Features

### 🔍 Automatic Detection
- Automatically finds `~/.config/nvim/` (or Windows equivalent)
- Recursively scans all `.lua` files in your config directory
- No manual configuration needed - just run the trainer!

### 🗺️ Keybinding Extraction
Parses multiple keymap syntaxes:
- `vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>')`
- `vim.api.nvim_set_keymap('n', '<leader>ff', ...)`
- `map('n', '<leader>ff', ...)`
- Plugin-specific keymaps in `lazy.nvim` and `packer.nvim` configs
- `which-key.nvim` registrations

### 🔌 Plugin Detection
Automatically detects and tracks:
- `lazy.nvim` plugins
- `packer.nvim` plugins
- Plugin-specific keybindings defined in `keys = {}` tables

### 🎯 Leader Key Support
- Automatically extracts your `vim.g.mapleader` setting
- Replaces `<leader>` with your actual leader key in training
- Supports `<localleader>` as well

## How It Works

### 1. Configuration Detection

The trainer looks for Neovim configs in these locations (in order):

**Unix/Linux/Mac:**
- `~/.config/nvim/`
- `$XDG_CONFIG_HOME/nvim/`

**Windows:**
- `%LOCALAPPDATA%\nvim\`
- `%USERPROFILE%\AppData\Local\nvim\`

### 2. Lua File Parsing

The parser recursively scans all `.lua` files and extracts:

```lua
-- Leader key
vim.g.mapleader = " "

-- Keymaps
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = 'Find Files' })
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { desc = 'Live Grep' })

-- Plugin configs (lazy.nvim)
{
  'nvim-telescope/telescope.nvim',
  keys = {
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find Files' },
  }
}
```

### 3. AI Context Integration

All extracted keybindings are provided to Claude AI for:
- **Keystroke Analysis** - Compare your keystrokes to your custom bindings
- **Personalized Feedback** - AI understands YOUR specific setup
- **Custom Training** - Practice the keybindings YOU actually use

## Game Modes

### 🎯 Custom Keybindings Mode (NEW!)

This mode is specifically designed to train YOU on YOUR setup:

**Features:**
- Shows random keybindings from YOUR config
- Displays what each keybinding does (from descriptions or comments)
- Shows which file/plugin defines each keybinding
- Tracks which unique keybindings you've practiced
- Higher XP for complex custom keybindings

**What You'll See:**
```
🎯 Custom Keybindings - YOUR Setup!

✓ Neovim config loaded: 127 keymaps
✓ Plugins detected: 42

Press this keybinding:

  <Space>ff

What it does: Find Files
Plugin: telescope.nvim
From: lua/plugins/telescope.lua

Tasks Completed: 15
Current Streak: 5
XP Earned: 1,250
```

### ⚡ Vim Motions Mode (Enhanced)

Now uses your config for AI feedback:
- AI knows your custom motions
- Suggests improvements based on YOUR keybindings
- Recognizes when you use your custom commands

## Configuration

### Automatic (Recommended)

Just run the trainer - it will auto-detect your Neovim config:

```bash
python -m src.main
```

### Manual Override

If your Neovim config is in a non-standard location, set it in `.env`:

```env
NVIM_CONFIG_DIR=/path/to/your/nvim/config
```

## Examples

### Example 1: Telescope User

If your config has:
```lua
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
```

The trainer will:
1. Detect these keybindings
2. Let you practice them in Custom Keybindings mode
3. Provide AI feedback that understands you use Telescope
4. Track which Telescope shortcuts you've mastered

### Example 2: Which-Key User

If you use `which-key.nvim`:
```lua
require('which-key').register({
  ['<leader>f'] = { name = '+file' },
  ['<leader>ff'] = { '<cmd>Telescope find_files<cr>', 'Find Files' },
  ['<leader>fr'] = { '<cmd>Telescope oldfiles<cr>', 'Recent Files' },
})
```

The trainer extracts descriptions and organizes training by category.

### Example 3: Lazy.nvim User

If you use `lazy.nvim`:
```lua
return {
  {
    'nvim-telescope/telescope.nvim',
    keys = {
      { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find Files' },
      { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live Grep' },
    },
  },
}
```

The trainer:
- Detects Telescope plugin
- Extracts all keybindings defined in `keys = {}`
- Associates them with the plugin
- Includes them in training

## Statistics

The Custom Keybindings mode tracks:
- **Unique Keybindings Practiced** - How many different shortcuts you've used
- **Plugin Coverage** - Which plugins' keybindings you've practiced
- **Mode Distribution** - Normal, Insert, Visual mode keybinding practice
- **Efficiency** - How quickly you execute your custom shortcuts

## Supported Features

### ✅ Fully Supported

- [x] `vim.keymap.set()` syntax
- [x] `vim.api.nvim_set_keymap()` syntax
- [x] `map()` function calls
- [x] Leader key (`<leader>`, `<localleader>`)
- [x] Multiple modes (n, i, v, x, c, t, o)
- [x] Keymap options (noremap, silent, expr)
- [x] Descriptions from `desc = ''` parameter
- [x] lazy.nvim `keys = {}` definitions
- [x] packer.nvim `use` statements
- [x] which-key.nvim registrations
- [x] Plugin detection

### 🚧 Partial Support

- [ ] Complex Lua functions as RHS (shows as "[function]")
- [ ] Conditional keymaps (only includes evaluated ones)
- [ ] Buffer-local keymaps (included but not distinguished)

### ❌ Not Supported

- [ ] Vimscript embedded in Lua (`vim.cmd`)
- [ ] Dynamic keymaps created at runtime
- [ ] Autocommand-created keymaps

## Troubleshooting

### "No custom configurations found"

**Causes:**
- Neovim config not in standard location
- No `.lua` files in config directory
- Keymaps defined only in Vimscript

**Solutions:**
1. Set `NVIM_CONFIG_DIR` in `.env`
2. Check that your `init.lua` exists
3. Verify keymaps are in Lua syntax

### "Using fallback keymaps"

This means no Neovim or Vim config was detected. The trainer will use common vim keybindings as fallback.

**To fix:**
- Set `NVIM_CONFIG_DIR` or `VIMRC_PATH` in `.env`
- Ensure config directory has `.lua` files

### "Keybinding not detected"

**Possible reasons:**
- Keybinding defined in Vimscript instead of Lua
- Complex Lua syntax the parser doesn't recognize
- Keybinding created dynamically

**Workaround:**
The parser extracts most common patterns. If some keybindings are missing, they'll be included in AI feedback context from other modes.

## Privacy & Security

🔒 **All parsing is done locally on your machine**
- Your config files never leave your computer
- Only summaries are sent to Claude API (if AI features are enabled)
- No sensitive data (API keys, passwords) is extracted

## Technical Details

### Parser Implementation

**File:** `src/core/nvim_parser.py`

**Key Components:**
- `NvimConfigParser` - Main parser class
- `NvimKeymap` - Data model for keybindings
- `PluginConfig` - Data model for plugins

**Parsing Strategy:**
1. Recursively find all `.lua` files
2. Extract leader key from `init.lua`
3. Use regex patterns to match keymap definitions
4. Parse options tables for descriptions
5. Build structured keymap database

### Integration Points

**AI Context:**
- `src/ai/keystroke_analyzer.py` - Loads keymap summary for AI
- `src/game_modes/vim_motions.py` - Uses context for feedback

**Configuration:**
- `src/core/config.py` - Auto-detects Neovim directory
- Adds `nvim_config_dir` field

**Game Modes:**
- `src/game_modes/custom_keybindings.py` - NEW mode for personalized training

## Future Enhancements

Planned improvements:
- [ ] Visual keymap browser/explorer
- [ ] Keymap conflict detection
- [ ] Plugin-specific training modes
- [ ] Import/export keymap presets
- [ ] Community keymap sharing
- [ ] Vim motion sequence optimization suggestions

## Examples of Detected Configs

### Minimal Config
```lua
vim.g.mapleader = " "
vim.keymap.set('n', '<leader>w', ':w<CR>')
```
✅ **Detected:** 1 keymap, leader = Space

### Medium Config (~50 keymaps)
```lua
-- Plugin manager + configs
-- Telescope, LSP, Treesitter, etc.
```
✅ **Detected:** 50+ keymaps across multiple plugins

### Large Config (~200+ keymaps)
```lua
-- Full featured IDE setup
-- Many plugins with custom keybindings
```
✅ **Detected:** 200+ keymaps, 50+ plugins

## Benefits

### 🎯 Personalized Training
- Practice keybindings YOU actually use
- No wasted time on irrelevant shortcuts
- Build muscle memory for YOUR workflow

### 🚀 Faster Learning
- Visual reinforcement of your custom setup
- AI feedback tailored to your configuration
- Understand which keybindings you use most

### 📊 Better Insights
- See which plugins you use most
- Identify underutilized keybindings
- Optimize your workflow

---

**Start training on YOUR setup today!** 🎉

Just run the trainer - it will automatically detect and parse your Neovim configuration.

```bash
python -m src.main
# Select: 🎯 Custom Keybindings - YOUR Neovim/Vim Setup!
```
