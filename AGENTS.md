# Agent Guide for NVIM-Typing-Kata-Trainer

This document serves as a comprehensive guide for AI agents and developers working on the `NVIM-Typing-Kata-Trainer` repository. It outlines the project structure, development workflows, and coding standards required to maintain high-quality contributions.

## Project Overview

`NVIM-Typing-Kata-Trainer` is a native Neovim plugin designed to gamify typing practice directly within the editor.
- **Core Philosophy:** "Don't simulate vim - use real vim!"
- **Stack:** Pure Lua (Neovim Lua API). Zero external dependencies.
- **Architecture:** Modular design with separate core logic, UI components, and game modes inheriting from a base class.

## 1. Build, Lint, and Test Commands

Since this is a Lua plugin for Neovim, there is no traditional "build" step. However, strict testing and syntax verification are required.

### Syntax Checking (Linting)
Before committing any code, ensure all Lua files are syntactically correct.
```bash
lua check_syntax.lua
```
*Output:* Checks specific files listed in the script and reports success (`✅`) or failure (`❌`) with error details.

### Testing
Testing is primarily manual/integration-based, running the plugin in an isolated Neovim instance to ensure no conflict with the user's config.

**Run the Test Instance:**
```bash
# Unix/Linux/MacOS
./test.sh

# Windows (Command Prompt/PowerShell)
nvim -u test_init.lua
```
*Behavior:* This launches Neovim with `test_init.lua`, effectively mocking a user's setup. It loads the plugin from the current directory.

**Manual Verification Steps:**
1.  **Load:** Ensure "Typing Kata Plugin Loaded!" notification appears.
2.  **Menu:** Run `:TypingKata` to open the main menu.
3.  **Game Modes:** Test specific modes (e.g., Symbol Training, Snake Apple) to ensure input handling works.
4.  **Persistence:** Check if stats save to `data/` or the standard data path on exit.

### Debugging
To enable debug logging, modify `test_init.lua` temporarily:
```lua
require('typing_kata').setup({
  debug = true
})
```
Use `print(vim.inspect(...))` or `vim.notify(...)` for ad-hoc debugging during development.

## 2. Code Style & Conventions

Adhere strictly to the following Lua and Neovim-specific conventions.

### Formatting
- **Indentation:** 2 spaces (soft tabs). No tabs.
- **Line Length:** Aim for 80-100 characters.
- **Quotes:** Use single quotes `'string'` by default. Use double quotes only if the string contains single quotes.
- **Semicolons:** Do NOT use semicolons `;` at the end of statements.
- **Whitespace:**
    - Space after `--` comments.
    - Space after commas in tables: `{ one, two, three }`.
    - No trailing whitespace.

### Naming
- **Variables/Functions:** `snake_case` (e.g., `local player_score`, `function calculate_xp()`).
- **Private Functions:** Local to the file. Do not expose helper functions in the returned table unless necessary.
- **Modules:** Use the `M` pattern:
  ```lua
  local M = {}
  -- ... code ...
  return M
  ```
- **Constants:** `UPPER_CASE_SNAKE` (e.g., `MAX_LIVES = 3`).
- **Files:** `snake_case.lua` (e.g., `snake_apple.lua`).

### Code Structure
- **Imports:** Place all `require` calls at the top of the file.
  ```lua
  local config = require('typing_kata.config')
  local utils = require('typing_kata.utils')
  ```
- **Module Definition:**
  1.  Imports
  2.  Module table declaration (`local M = {}`)
  3.  Local variables/constants
  4.  Local helper functions
  5.  Public module functions (`function M.setup()`)
  6.  Return statement (`return M`)

### Neovim API Usage
- **API:** Prefer `vim.api.*` functions over `vim.cmd(...)` for better performance and safety.
  - *Good:* `vim.api.nvim_buf_set_lines(...)`
  - *Bad:* `vim.cmd('call setline(...)')`
- **Keymaps:** Use `vim.keymap.set` instead of `vim.api.nvim_set_keymap` when possible for easier Lua callback integration.
- **Autocommands:** Use `vim.api.nvim_create_autocmd` within an `augroup`.
  ```lua
  local group = vim.api.nvim_create_augroup('MyGroup', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'lua',
    callback = function() ... end
  })
  ```

### Error Handling
- **File I/O:** Always check if `io.open` returns a handle.
  ```lua
  local file = io.open(path, 'r')
  if not file then return nil end
  ```
- **JSON:** Use `pcall` when decoding JSON to prevent crashes on corrupted data.
  ```lua
  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('Error decoding JSON', vim.log.levels.ERROR)
  end
  ```
- **Validation:** Validate function inputs, especially public API methods.

### Documentation
- **Comments:** Use `--` for simple comments.
- **Docstrings:** For public functions, briefly explain parameters and return values.
  ```lua
  --- Calculates experience points based on accuracy and speed
  --- @param accuracy number: Percentage (0-100)
  --- @param wpm number: Words per minute
  --- @return number: The calculated XP
  function M.calculate_xp(accuracy, wpm) ... end
  ```

## 3. Directory Structure

- `lua/typing_kata/`: Source code root.
  - `core/`: Business logic (player, session, xp, ranks).
  - `ui/`: Visual components (menu, windows, highlights).
  - `modes/`: Game implementations (inherit from `base_mode.lua`).
- `plugin/`: Auto-loaded scripts (minimal entry point).
- `docs/`: Comprehensive documentation.
- `tests/`: (If available) Unit tests.

## 4. Specific Rules

- **Zero Dependencies:** Do not introduce external Lua libraries (e.g., plenary.nvim) unless absolutely critical and approved. The plugin should be standalone.
- **Performance:** Minimizing startup time is crucial. Defer `require` calls inside functions if a module is heavy and not always needed.
- **UI:** Use floating windows for menus and game interfaces to avoid disrupting the user's buffer layout.

## 5. Game Mode Implementation Guide

When creating a new game mode:
1.  Create `lua/typing_kata/modes/your_mode.lua`.
2.  Inherit from `base_mode`:
    ```lua
    local BaseMode = require('typing_kata.modes.base_mode')
    local M = setmetatable({}, { __index = BaseMode })
    ```
3.  Implement required methods:
    - `setup()`
    - `update(key)`
    - `generate_task()`
    - `render()`
4.  Register the mode in `lua/typing_kata/ui/menu.lua`.

---
*Generated for AI Agents to ensure consistency and quality in the NVIM-Typing-Kata-Trainer repository.*
