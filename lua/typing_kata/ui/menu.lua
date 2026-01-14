-- Main menu UI (floating window)
local M = {}

local buffer_utils = require('typing_kata.ui.buffer')
local ranks = require('typing_kata.core.ranks')
local config = require('typing_kata.config')

-- Constants for layout
local WIDTH = 60

-- Helper to center text in a width
local function center(text, width)
  local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
  return string.rep(' ', padding) .. text
end

-- Helper to draw a progress bar
local function draw_progress_bar(percent, width)
  local filled_len = math.floor((percent / 100) * width)
  local empty_len = width - filled_len
  return '[' .. string.rep('=', filled_len) .. string.rep('-', empty_len) .. ']'
end

-- Show main menu
function M.show(player)
  local buf = buffer_utils.create_scratch_buffer('Typing Kata Menu')
  M.render_menu(buf, player)

  local ui_config = config.current.ui
  local win = buffer_utils.create_floating_window(buf, {
    width = WIDTH + 4, -- Add padding for borders
    height = 25, -- Fixed height for consistency
    position = ui_config.menu_position,
    border = 'rounded', -- Use Nvim's native rounded border if available
    title = ' NVIM TYPING KATA ',
  })

  if not win then
    vim.notify('Failed to create menu window', vim.log.levels.ERROR)
    return
  end

  M.setup_keymaps(buf, win, player)
end

-- Render menu content
function M.render_menu(buf, player)
  local rank = ranks.get_rank_by_xp(player.current_xp)
  local progress = ranks.progress_to_next_rank(player.current_xp)
  
  local lines = {}
  local sep_line = '─'
  
  -- 1. Header & Player Stats
  table.insert(lines, '')
  table.insert(lines, center(string.format('%s %s', rank.symbol, rank.name), WIDTH))
  table.insert(lines, center(string.format('XP: %d', player.current_xp), WIDTH))
  
  -- Progress Bar
  local bar_str = draw_progress_bar(progress, 30)
  table.insert(lines, center(string.format('%s %d%%', bar_str, progress), WIDTH))
  table.insert(lines, '')

  -- 2. Menu Sections
  local function add_section(title, items)
    local header = '╭─ ' .. title .. ' ' .. string.rep('─', WIDTH - #title - 5) .. '╮'
    table.insert(lines, header)
    for _, item in ipairs(items) do
      -- Format: "  [key] Name"
      local entry = string.format('│  [%s] %-48s │', item.key, item.name)
      table.insert(lines, entry)
    end
    table.insert(lines, '╰' .. string.rep('─', WIDTH - 2) .. '╯')
  end

  add_section('FUNDAMENTALS', {
    { key = '3', name = 'Symbol Training' },
    { key = '7', name = 'Comprehensive Keys' },
    { key = '1', name = 'Neovim Commands (Key Sequences)' },
  })
  
  add_section('PRACTICE MODES', {
    { key = '5', name = 'Word Typing (WPM)' },
    { key = '2', name = 'Snake Apple (Navigation)' },
    { key = '6', name = 'Vim Motions' },
    { key = '4', name = 'Coding Lessons' },
  })
  
  add_section('QUIZZES', {
    { key = '8', name = 'Vim Motions Quiz' },
    { key = '9', name = 'Neovim Command Quiz' },
  })

  -- Footer
  table.insert(lines, '')
  table.insert(lines, center('[s] Stats    [q] Quit', WIDTH))
  table.insert(lines, '')

  buffer_utils.set_content(buf, lines)
end

-- Setup menu keymaps
function M.setup_keymaps(buf, win, player)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Mode launch keys (1-9)
  local mode_mapping = {
    'custom_keybindings',
    'snake_apple',
    'symbol_training',
    'coding_lessons',
    'word_typing',
    'vim_motions',
    'comprehensive_keys',
    'vim_motions_quiz',
    'nvim_command_quiz',
  }

  for i = 1, 9 do
    vim.keymap.set('n', tostring(i), function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end

      local mode_name = mode_mapping[i]
      local ok, mode_module = pcall(require, 'typing_kata.modes.' .. mode_name)

      if not ok then
        vim.notify('Mode error: ' .. mode_name, vim.log.levels.WARN)
        M.show(player)
        return
      end

      local mode = mode_module:new(player)
      mode:start()
    end, opts)
  end

  -- Stats
  vim.keymap.set('n', 's', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    require('typing_kata.ui.stats').show(player)
  end, opts)

  -- Quit
  local function quit()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set('n', 'q', quit, opts)
  vim.keymap.set('n', '<Esc>', quit, opts)
end

return M
