-- Main menu UI (floating window)
local M = {}

local buffer_utils = require('typing_kata.ui.buffer')
local ranks = require('typing_kata.core.ranks')
local config = require('typing_kata.config')

-- Show main menu
function M.show(player)
  -- Create buffer
  local buf = buffer_utils.create_scratch_buffer('Typing Kata Menu')

  -- Render menu content
  M.render_menu(buf, player)

  -- Create floating window
  local ui_config = config.current.ui
  local win = buffer_utils.create_floating_window(buf, {
    width = ui_config.menu_size.width,
    height = ui_config.menu_size.height,
    position = ui_config.menu_position,
    border = ui_config.border,
    title = ' NVIM TYPING KATA TRAINER ',
  })

  if not win then
    vim.notify('Failed to create menu window', vim.log.levels.ERROR)
    return
  end

  -- Setup keymaps
  M.setup_keymaps(buf, win, player)
end

-- Render menu content
function M.render_menu(buf, player)
  local rank = ranks.get_rank_by_xp(player.current_xp)
  local progress = ranks.progress_to_next_rank(player.current_xp)

  local lines = {
    '',
    '          NVIM TYPING KATA TRAINER',
    '          ========================',
    '',
    string.format('     %s %s | XP: %d', rank.symbol, rank.name, player.current_xp),
    string.format('     Progress to Next Rank: %.1f%%', progress),
    '',
    '     TRAINING MODES',
    '     ──────────────',
    '       1  ⌨️   Neovim Commands (Key Sequences)',
    '       2  🐍  Snake Apple (Find 🍎 in code!)',
    '       3  🔣  Symbol Training',
    '       4  💻  Coding Lessons',
    '       5  📝  Word Typing (Paragraph)',
    '       6  ⚡  Vim Motions (Key Sequences)',
    '       7  🔤  Comprehensive Keys',
    '       8  🎓  Vim Motions Quiz',
    '       9  🔧  Neovim Command Quiz',
    '',
    '       s  📊  Stats',
    '       q  Exit',
    '',
    '     Press number to select mode',
    '',
  }

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
      -- Close menu
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end

      -- Launch mode
      local mode_name = mode_mapping[i]
      local ok, mode_module = pcall(require, 'typing_kata.modes.' .. mode_name)

      if not ok then
        vim.notify('Mode not yet implemented: ' .. mode_name, vim.log.levels.WARN)
        M.show(player)  -- Return to menu
        return
      end

      local mode = mode_module:new(player)
      mode:start()
    end, opts)
  end

  -- Stats screen
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
