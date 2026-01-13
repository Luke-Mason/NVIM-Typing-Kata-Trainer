-- Main plugin entry point
local M = {}

-- Modules
local config = require('typing_kata.config')
local player_module = require('typing_kata.core.player')
local menu = require('typing_kata.ui.menu')
local highlights = require('typing_kata.ui.highlights')

-- Plugin state
M.player = nil

-- Setup function (called by user in init.lua)
function M.setup(opts)
  -- Merge user config with defaults
  config.current = vim.tbl_deep_extend('force', config.defaults, opts or {})

  -- Load player profile
  M.player = player_module.load()

  -- Setup highlights
  highlights.setup()

  -- Create user commands
  M.create_commands()

  -- Create autocommands
  M.create_autocmds()
end

-- Create user commands
function M.create_commands()
  vim.api.nvim_create_user_command('TypingKata', function()
    M.open()
  end, { desc = 'Open Typing Kata Trainer' })

  vim.api.nvim_create_user_command('TypingKataStats', function()
    require('typing_kata.ui.stats').show(M.player)
  end, { desc = 'Show Typing Kata Stats' })

  vim.api.nvim_create_user_command('TypingKataRank', function()
    local ranks = require('typing_kata.core.ranks')
    local rank = ranks.get_rank_by_xp(M.player.current_xp)
    local progress = ranks.progress_to_next_rank(M.player.current_xp)

    local message = string.format(
      '%s %s | XP: %d | Progress: %.1f%%',
      rank.symbol,
      rank.name,
      M.player.current_xp,
      progress
    )

    vim.notify(message, vim.log.levels.INFO)
  end, { desc = 'Show Current Rank' })
end

-- Create autocommands
function M.create_autocmds()
  local group = vim.api.nvim_create_augroup('TypingKata', { clear = true })

  -- Auto-save player progress when exiting Neovim
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      if M.player then
        player_module.save(M.player)
      end
    end,
  })
end

-- Main entry: open menu
function M.open()
  if not M.player then
    M.player = player_module.load()
  end
  menu.show(M.player)
end

-- Get statusline component (for statusline integration)
function M.get_statusline_component()
  if not M.player then
    return ''
  end

  local ranks = require('typing_kata.core.ranks')
  local rank = ranks.get_rank_by_xp(M.player.current_xp)

  return string.format('%s %s (XP: %d)', rank.symbol, rank.name, M.player.current_xp)
end

return M
