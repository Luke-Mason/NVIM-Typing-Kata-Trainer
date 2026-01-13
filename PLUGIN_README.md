# NVIM Typing Kata Trainer - Plugin

A gamified typing trainer built as a native Neovim plugin with 8 game modes, 100 ranks, and real vim integration.

## Features

- 🎮 **8 Game Modes** - Symbol Training, Word Typing (WPM), Snake Apple (vim navigation), and more
- 🏆 **100 Ranks** - Progress from Recruit to Ultimate Vim God
- 📊 **Stats Tracking** - Per-mode accuracy, WPM, streaks, and XP
- 🎯 **Real Vim Motions** - Use actual Neovim, `5w`, `d3w` all work!
- 💾 **Persistent Progress** - JSON-based save system
- 🎨 **Native UI** - Floating windows, buffers, and highlights
- 🚀 **Zero Dependencies** - Pure Lua, no external libraries

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  'yourusername/nvim-typing-kata',
  config = function()
    require('typing_kata').setup({
      -- Optional configuration
      keymaps = {
        open_menu = '<leader>tk',  -- Open typing trainer
      },
      ui = {
        menu_size = { width = 70, height = 25 },
        border = 'rounded',
      },
    })
  end,
  keys = {
    { '<leader>tk', '<cmd>TypingKata<cr>', desc = 'Open Typing Trainer' },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/nvim-typing-kata',
  config = function()
    require('typing_kata').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'yourusername/nvim-typing-kata'

lua << EOF
require('typing_kata').setup()
EOF
```

## Usage

### Commands

- `:TypingKata` - Open the main menu
- `:TypingKataStats` - View your stats and progress
- `:TypingKataRank` - Quick rank display

### Default Keybindings

- `<leader>tk` - Open typing trainer (configurable)
- Numbers `1-7` - Select game mode in menu
- `s` - View stats (in menu)
- `q` or `ESC` - Exit/Go back

## Game Modes

### Implemented Modes

#### 1. 📝 Word Typing (Mode 5)
Monkeytype-style WPM training with 200+ common words.
- Type words character-by-character
- Real-time WPM tracking
- 20 words per session
- **Status**: ✅ Fully Implemented

#### 2. 🔣 Symbol Training (Mode 3)
Practice special characters and programming symbols.
- Single characters and combinations (`->`, `==`, etc.)
- 50 symbols per session
- Focus on accuracy and speed
- **Status**: ✅ Fully Implemented

#### 3. 🐍 Snake Apple (Mode 2)
Grid navigation with REAL vim motions!
- Navigate to collect apples using h/j/k/l, w/b/e, 0/$, gg/G
- Uses actual Neovim cursor tracking
- Efficiency scoring based on optimal path
- **Status**: ✅ Fully Implemented with Real Vim Motions!

### Coming Soon

- 🎯 **Custom Keybindings** - Practice your actual Neovim config
- ⌨️ **Comprehensive Keys** - All keyboard keys systematically
- 💻 **Coding Lessons** - Type real code snippets
- ⚡ **Vim Motions** - Complex vim editing challenges with real vim

## Progression System

### XP & Ranks

- Earn XP from completing tasks with bonuses for:
  - **Accuracy** (0-10 XP bonus)
  - **Speed/WPM** (0-5 XP bonus)
  - **Streaks** (0-15 XP bonus, capped)
- **100 Ranks** from Recruit to Ultimate Vim God
- Exponential XP curve for balanced progression

### Stats Tracking

- Per-mode statistics (accuracy, WPM, streaks)
- Total playtime and sessions
- Best personal records
- All saved to JSON in `~/.local/share/nvim/typing_kata/`

## Configuration

Default configuration:

```lua
require('typing_kata').setup({
  -- Data directory for saves
  data_dir = vim.fn.stdpath('data') .. '/typing_kata',

  -- Keybindings
  keymaps = {
    open_menu = '<leader>tk',
    exit_mode = '<Esc>',
  },

  -- UI settings
  ui = {
    menu_position = 'center',  -- 'center', 'top', 'bottom'
    menu_size = { width = 70, height = 25 },
    border = 'rounded',        -- 'none', 'single', 'double', 'rounded'
  },

  -- Statusline integration
  statusline = {
    enabled = true,
    show_rank = true,
    show_xp = true,
  },

  debug = false,
})
```

### Statusline Integration

To show your rank in your statusline:

```lua
-- Example with lualine
require('lualine').setup {
  sections = {
    lualine_x = {
      function()
        return require('typing_kata').get_statusline_component()
      end,
    },
  },
}
```

## Architecture

This plugin follows the architecture specified in `docs/NEOVIM_PLUGIN_ARCHITECTURE.md`:

- **Pure Lua** - No external dependencies
- **Buffer-based** - Uses Neovim buffers for display
- **Real Vim Motions** - Snake Apple uses actual cursor tracking
- **Modular** - Easy to add new game modes
- **Extensible** - Base mode class pattern

## Development Status

### ✅ Completed
- Core infrastructure (player, ranks, XP, session)
- Main menu UI (floating window)
- Symbol Training mode
- Word Typing mode (WPM)
- Snake Apple mode (with real vim motions!)
- Stats display screen
- Persistent save system

### 🚧 In Progress
- Custom Keybindings mode (needs config parser)
- Comprehensive Keys mode
- Coding Lessons mode
- Vim Motions mode
- Help documentation

### 📋 Planned
- Statusline component
- More robust input handling
- Additional game modes
- Achievements system

## Requirements

- Neovim 0.9.0 or higher
- No external dependencies!

## Contributing

This plugin is built according to the specifications in the `docs/` folder. See:
- `docs/PROJECT_OVERVIEW.md` - Project vision and goals
- `docs/NEOVIM_PLUGIN_ARCHITECTURE.md` - Architecture details
- `docs/GAME_MODES_SPECIFICATION.md` - Game mode specs
- `docs/PROGRESSION_SYSTEM.md` - XP and rank system

## Credits

- Inspired by: Monkeytype, vim-be-good, and the Neovim community
- Built from lessons learned in the Python TUI prototype
- See `docs/LESSONS_LEARNED.md` for the journey

## License

[License TBD]

## Support

For issues or feature requests, please open an issue on GitHub.

---

**Start training:** `:TypingKata` or `<leader>tk`

Happy typing! 🎯
