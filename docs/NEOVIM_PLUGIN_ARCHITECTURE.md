# Neovim Plugin Architecture Proposal

Design specification for building the typing trainer as a native Neovim plugin.

---

## Plugin Overview

**Name**: `nvim-typing-kata` (or `typing-trainer.nvim`)
**Language**: Lua
**Target**: Neovim 0.9+
**Dependencies**: None (pure Lua)

### Core Advantages Over Python TUI

1. **Real Vim Motions** - `5w`, `d3w`, `ciw` work natively
2. **Native Integration** - No separate window, works in Neovim
3. **Buffer-Based Display** - Use actual buffers as game screens
4. **Extmarks & Highlights** - Rich visuals without external rendering
5. **Floating Windows** - Native menus and overlays
6. **Autocommands** - React to real vim events
7. **Zero Dependencies** - No Python, no external libraries
8. **Fast** - Lua is fast, no IPC overhead

---

## Directory Structure

```
nvim-typing-kata/
├── lua/
│   └── typing_kata/
│       ├── init.lua              # Plugin entry point
│       ├── config.lua            # User configuration
│       │
│       ├── core/
│       │   ├── player.lua        # Player data & persistence
│       │   ├── session.lua       # Game session tracking
│       │   ├── ranks.lua         # Rank system (100 ranks)
│       │   └── xp.lua            # XP calculation formulas
│       │
│       ├── ui/
│       │   ├── menu.lua          # Floating window menu
│       │   ├── buffer.lua        # Buffer rendering helpers
│       │   ├── highlights.lua    # Highlight group definitions
│       │   └── statusline.lua    # Rank display in statusline
│       │
│       ├── modes/
│       │   ├── base_mode.lua     # Abstract base class
│       │   ├── word_typing.lua   # Mode 5: Word typing (WPM)
│       │   ├── snake_apple.lua   # Mode 2: Snake game
│       │   ├── symbol_training.lua
│       │   ├── coding_lessons.lua
│       │   ├── custom_keybindings.lua
│       │   ├── vim_motions.lua
│       │   └── comprehensive_keys.lua
│       │
│       ├── parsers/
│       │   └── keybindings.lua   # Parse user's init.lua for keybindings
│       │
│       └── utils/
│           ├── json.lua          # JSON encode/decode (vim.json wrapper)
│           └── stats.lua         # Stats calculation helpers
│
├── data/
│   └── ranks.json                # 100 rank definitions
│
├── plugin/
│   └── typing_kata.vim           # Plugin initialization (Vim script)
│
├── doc/
│   └── typing_kata.txt           # Help documentation (:help typing-kata)
│
└── README.md
```

---

## Core Architecture

### 1. Plugin Entry Point

**File**: `lua/typing_kata/init.lua`

```lua
local M = {}

-- Configuration
M.config = require('typing_kata.config')

-- Core modules
local player = require('typing_kata.core.player')
local menu = require('typing_kata.ui.menu')

-- Plugin state
M.player = nil
M.current_mode = nil

-- Setup function (called by user in init.lua)
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend('force', M.config.defaults, opts or {})

  -- Load player profile
  M.player = player.load()

  -- Create user commands
  M.create_commands()

  -- Create autocommands
  M.create_autocmds()

  -- Setup keymaps (if configured)
  M.setup_keymaps()
end

-- Main entry: open menu
function M.open()
  menu.show(M.player)
end

return M
```

**User Configuration** (`init.lua`):
```lua
require('typing_kata').setup({
  -- Data directory for saves
  data_dir = vim.fn.stdpath('data') .. '/typing_trainer',

  -- Keybindings
  keymaps = {
    open_menu = '<leader>tk',  -- Open typing trainer
    exit_mode = 'jk',          -- Exit any game mode
  },

  -- UI settings
  ui = {
    menu_position = 'center',  -- 'center', 'top', 'bottom'
    menu_size = { width = 60, height = 20 },
  },

  -- Statusline integration
  statusline = {
    enabled = true,
    show_rank = true,
    show_xp = true,
  },
})

-- Optional: Keymap to open trainer
vim.keymap.set('n', '<leader>tk', ':TypingKata<CR>', { desc = 'Open Typing Trainer' })
```

---

### 2. Game Mode Base Class

**File**: `lua/typing_kata/modes/base_mode.lua`

```lua
local BaseMode = {}
BaseMode.__index = BaseMode

function BaseMode:new(player, mode_name)
  local obj = {
    player = player,
    mode_name = mode_name,
    session = nil,
    is_running = false,
    buffer = nil,
    window = nil,
  }
  setmetatable(obj, self)
  return obj
end

-- Abstract methods (must be overridden)
function BaseMode:setup()
  error("setup() must be implemented by subclass")
end

function BaseMode:update(key)
  error("update(key) must be implemented by subclass")
end

function BaseMode:generate_task()
  error("generate_task() must be implemented by subclass")
end

function BaseMode:render()
  error("render() must be implemented by subclass")
end

function BaseMode:calculate_xp()
  error("calculate_xp() must be implemented by subclass")
end

-- Concrete methods (provided by base)
function BaseMode:start()
  self.session = require('typing_kata.core.session').new(self.mode_name)
  self.is_running = true

  self:setup()
  self:generate_task()
  self:create_buffer()
  self:render()
end

function BaseMode:create_buffer()
  -- Create new scratch buffer
  self.buffer = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(self.buffer, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(self.buffer, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', false)

  -- Open in current window or floating window
  vim.api.nvim_set_current_buf(self.buffer)

  -- Setup keymaps for this buffer
  self:setup_buffer_keymaps()
end

function BaseMode:setup_buffer_keymaps()
  local opts = { buffer = self.buffer, noremap = true, silent = true }

  -- Exit on 'jk' or ESC
  vim.keymap.set('n', '<Esc>', function() self:exit() end, opts)

  -- Mode-specific keymaps (override in subclass)
end

function BaseMode:handle_input(key)
  local task_complete = self:update(key)

  if task_complete then
    local xp = self:calculate_xp()
    self.session:add_task_completion(xp)
    self:generate_task()
  end

  self:render()
end

function BaseMode:exit()
  self.is_running = false
  self.session:end_session()

  -- Update player stats
  self.player:update_from_session(self.session)

  -- Save player
  require('typing_kata.core.player').save(self.player)

  -- Show summary
  self:show_summary()

  -- Close buffer
  vim.api.nvim_buf_delete(self.buffer, { force = true })
end

function BaseMode:show_summary()
  local summary = self.session:get_summary()
  -- Display in floating window or notification
  vim.notify(summary, vim.log.levels.INFO)
end

return BaseMode
```

---

### 3. Example Mode: Word Typing

**File**: `lua/typing_kata/modes/word_typing.lua`

```lua
local BaseMode = require('typing_kata.modes.base_mode')
local WordTyping = setmetatable({}, { __index = BaseMode })

-- Common words list
WordTyping.WORDS = {
  "the", "be", "to", "of", "and", "a", "in", "that", "have", "I",
  "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
  -- ... 200+ words
}

function WordTyping:new(player)
  local obj = BaseMode:new(player, 'word_typing')
  setmetatable(obj, { __index = self })

  obj.words_per_session = 20
  obj.word_list = {}
  obj.current_word_idx = 1
  obj.typed_text = ""
  obj.start_time = nil

  return obj
end

function WordTyping:setup()
  -- Nothing to setup
end

function WordTyping:generate_task()
  if #self.word_list == 0 then
    -- Generate word list
    for i = 1, self.words_per_session do
      local word = self.WORDS[math.random(#self.WORDS)]
      table.insert(self.word_list, word)
    end
    self.current_word_idx = 1
    self.typed_text = ""
    self.start_time = vim.loop.now()
  end
end

function WordTyping:setup_buffer_keymaps()
  BaseMode.setup_buffer_keymaps(self)

  local opts = { buffer = self.buffer, noremap = true, silent = true }

  -- Handle character typing in insert mode
  vim.api.nvim_create_autocmd("InsertCharPre", {
    buffer = self.buffer,
    callback = function()
      local char = vim.v.char
      self:handle_char(char)
      return true  -- Prevent char from being inserted
    end
  })

  -- Space to complete word
  vim.keymap.set('i', '<Space>', function()
    self:complete_word()
  end, opts)

  -- Backspace
  vim.keymap.set('i', '<BS>', function()
    self:backspace()
  end, opts)
end

function WordTyping:handle_char(char)
  local target_word = self.word_list[self.current_word_idx]
  local expected_char = target_word:sub(#self.typed_text + 1, #self.typed_text + 1)

  if char == expected_char then
    self.typed_text = self.typed_text .. char
    self.session:record_keystroke(true)
  else
    self.session:record_keystroke(false)
  end

  self:render()
end

function WordTyping:complete_word()
  local target_word = self.word_list[self.current_word_idx]

  if self.typed_text == target_word then
    -- Correct! Move to next word
    self.current_word_idx = self.current_word_idx + 1
    self.typed_text = ""
    self.session:increment_streak()

    if self.current_word_idx > self.words_per_session then
      -- Session complete!
      self:exit()
    end
  else
    -- Incorrect, mark error
    self.session:break_streak()
  end

  self:render()
end

function WordTyping:backspace()
  if #self.typed_text > 0 then
    self.typed_text = self.typed_text:sub(1, -2)
    self:render()
  end
end

function WordTyping:calculate_wpm()
  local elapsed = (vim.loop.now() - self.start_time) / 1000 / 60  -- minutes
  local chars_typed = self.session.correct_keystrokes
  return (chars_typed / 5) / elapsed  -- 5 chars per word
end

function WordTyping:render()
  local lines = {}

  -- Title
  table.insert(lines, "📝 Word Typing - WPM Training")
  table.insert(lines, "")

  -- Progress
  table.insert(lines, string.format("Progress: %d/%d", self.current_word_idx, self.words_per_session))
  table.insert(lines, "")

  -- Current word
  local target_word = self.word_list[self.current_word_idx]
  table.insert(lines, "Type this word:")
  table.insert(lines, "  " .. target_word)
  table.insert(lines, "")

  -- User typing (with color)
  table.insert(lines, "You typed: " .. self.typed_text)
  table.insert(lines, "")

  -- Stats
  local wpm = self:calculate_wpm()
  local accuracy = self.session:calculate_accuracy()
  table.insert(lines, string.format("WPM: %.1f", wpm))
  table.insert(lines, string.format("Accuracy: %.1f%%", accuracy))
  table.insert(lines, string.format("Streak: %d", self.session.current_streak))
  table.insert(lines, "")

  -- Instructions
  table.insert(lines, "Type each word then press Space | ESC to exit")

  -- Write to buffer
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', false)
end

function WordTyping:calculate_xp()
  local base_xp = 50
  local accuracy = self.session:calculate_accuracy()
  local wpm = self:calculate_wpm()

  return require('typing_kata.core.xp').calculate(base_xp, {
    accuracy = accuracy,
    wpm = wpm,
    streak = self.session.best_streak,
  })
end

return WordTyping
```

---

### 4. Menu System (Floating Window)

**File**: `lua/typing_kata/ui/menu.lua`

```lua
local M = {}

function M.show(player)
  -- Create floating window for menu
  local width = 60
  local height = 20
  local buf = vim.api.nvim_create_buf(false, true)

  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Render menu content
  M.render_menu(buf, player)

  -- Setup keymaps
  M.setup_keymaps(buf, win, player)
end

function M.render_menu(buf, player)
  local rank = require('typing_kata.core.ranks').get_by_xp(player.xp)

  local lines = {
    "NVIM TYPING KATA TRAINER",
    "",
    string.format("%s %s | XP: %d", rank.symbol, rank.name, player.xp),
    "",
    "TRAINING MODES",
    "──────────────",
    "  1 🎯 Custom Keybindings",
    "  2 🐍 Snake Apple",
    "  3 🔣 Symbol Training",
    "  4 💻 Coding Lessons",
    "  5 📝 Word Typing",
    "  6 ⚡ Vim Motions",
    "  7 ⌨️  Comprehensive Keys",
    "",
    "  s 📊 Stats",
    "  q Exit",
    "",
    "Press number to select mode",
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M.setup_keymaps(buf, win, player)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Number keys launch modes
  local modes = {
    require('typing_kata.modes.custom_keybindings'),
    require('typing_kata.modes.snake_apple'),
    require('typing_kata.modes.symbol_training'),
    require('typing_kata.modes.coding_lessons'),
    require('typing_kata.modes.word_typing'),
    require('typing_kata.modes.vim_motions'),
    require('typing_kata.modes.comprehensive_keys'),
  }

  for i = 1, 7 do
    vim.keymap.set('n', tostring(i), function()
      -- Close menu
      vim.api.nvim_win_close(win, true)

      -- Launch mode
      local mode = modes[i]:new(player)
      mode:start()
    end, opts)
  end

  -- Stats
  vim.keymap.set('n', 's', function()
    vim.api.nvim_win_close(win, true)
    require('typing_kata.ui.stats').show(player)
  end, opts)

  -- Quit
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
end

return M
```

---

## Key Advantages: Real Vim Integration

### Problem Solved: Real Vim Motions

**Python Version**: Couldn't do `5w`, `d3w`, etc.
**Neovim Plugin**: Uses actual vim!

#### Example: Snake Apple with Real Vim

```lua
function SnakeApple:setup_buffer_keymaps()
  -- Don't intercept every key!
  -- Let Neovim's native motions work

  -- Just track cursor position changes
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = self.buffer,
    callback = function()
      self:on_cursor_move()
    end
  })
end

function SnakeApple:on_cursor_move()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  -- Check if reached apple
  if row == self.apple_row and col == self.apple_col then
    self:collect_apple()
  end

  self:render()
end
```

**Result**: `5w`, `3j`, `0`, `$`, `gg`, `G` all work natively!

#### Example: Vim Motions Training

```lua
function VimMotions:setup()
  -- Create a real text buffer
  local text = {
    "function calculate_average(numbers) {",
    "  const sum = numbers.reduce((a, b) => a + b, 0);",
    "  return sum / numbers.length;",
    "}",
  }

  vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, text)

  -- Task: "Delete the word 'const' and replace with 'let'"
  self.task = "Change 'const' to 'let' on line 2"

  -- Record motions (optional)
  self.keystrokes = {}
end

-- User uses real vim: `/const<CR>cwlet<Esc>`
-- It actually works because it's real Neovim!
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1)
- [ ] Plugin structure and entry point
- [ ] Player save/load (JSON)
- [ ] Rank system
- [ ] XP calculation
- [ ] Session tracking
- [ ] Basic menu (floating window)

### Phase 2: Simple Modes (Week 2)
- [ ] Symbol Training (simplest mode)
- [ ] Comprehensive Keys
- [ ] Word Typing (WPM tracking)

### Phase 3: Visual Modes (Week 3)
- [ ] Snake Apple (buffer-based grid)
- [ ] Custom Keybindings (parse init.lua)

### Phase 4: Advanced Modes (Week 4)
- [ ] Coding Lessons (with fallback)
- [ ] Vim Motions (real vim integration!)

### Phase 5: Polish (Week 5)
- [ ] Stats screen
- [ ] Statusline integration
- [ ] Help documentation
- [ ] README and examples

---

## Installation & Usage

### Installation (lazy.nvim)

```lua
{
  'username/nvim-typing-kata',
  config = function()
    require('typing_kata').setup({
      keymaps = {
        open_menu = '<leader>tk',
      },
    })
  end,
}
```

### Usage

```vim
" Open typing trainer
:TypingKata

" Or use keymap
<leader>tk

" View stats
:TypingKataStats

" View progress
:TypingKataProgress
```

---

## Summary

**Key Architectural Decisions**:
1. Pure Lua - no dependencies
2. Buffer-based display - uses actual Neovim buffers
3. Real vim motions - `5w`, `d3w` work natively!
4. Floating windows - native menus
5. Autocommands - react to cursor movement
6. Extmarks - rich visuals
7. JSON persistence - compatible with Python version

**Advantages Over Python TUI**:
- ✅ Real vim integration
- ✅ No separate window
- ✅ Fast (Lua)
- ✅ Zero dependencies
- ✅ Native Neovim UI
- ✅ Statusline integration

**Next Steps**:
1. Create plugin repository
2. Implement Phase 1 (core)
3. Iterate on game modes
4. Test and refine
5. Publish to plugin managers
