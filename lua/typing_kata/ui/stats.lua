-- Stats display screen
local M = {}

local buffer_utils = require('typing_kata.ui.buffer')
local ranks = require('typing_kata.core.ranks')
local config = require('typing_kata.config')

-- Helper to center text
local function center(text, width)
  local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
  return string.rep(' ', padding) .. text
end

-- Format time
local function format_time(seconds)
  local hours = math.floor(seconds / 3600)
  local mins = math.floor((seconds % 3600) / 60)
  if hours > 0 then return string.format('%dh %dm', hours, mins) else return string.format('%dm', mins) end
end

function M.show(player)
  local buf = buffer_utils.create_scratch_buffer('Typing Kata Stats')
  M.render_stats(buf, player)

  local ui_config = config.current.ui
  local win = buffer_utils.create_floating_window(buf, {
    width = 70,
    height = 30,
    position = ui_config.menu_position,
    border = 'rounded',
    title = ' PLAYER STATISTICS ',
  })

  if not win then return end
  M.setup_keymaps(buf, win, player)
end

function M.render_stats(buf, player)
  local rank = ranks.get_rank_by_xp(player.current_xp)
  local progress = ranks.progress_to_next_rank(player.current_xp)
  local lines = {}
  local width = 66 -- buffer width minus padding roughly

  -- Header
  table.insert(lines, '')
  table.insert(lines, center(string.format('PLAYER: %s', player.name:upper()), width))
  table.insert(lines, center(string.format('%s %s', rank.symbol, rank.name), width))
  table.insert(lines, '')

  -- Global Stats Grid
  table.insert(lines, '╭─ GLOBAL STATS ─────────────────────────────────────────────────╮')
  table.insert(lines, string.format('│  XP: %-12d  Playtime: %-12s  Sessions: %-4d   │', 
    player.current_xp, format_time(player.total_playtime), player.total_sessions))
  table.insert(lines, '╰────────────────────────────────────────────────────────────────╯')
  table.insert(lines, '')

  -- Modes Grid
  table.insert(lines, '  MODE PERFORMANCE')
  table.insert(lines, '  ────────────────')

  local mode_names = {
    { key = 'word_typing', name = 'Word Typing' },
    { key = 'snake_apple', name = 'Snake Apple' },
    { key = 'vim_motions', name = 'Vim Motions' },
    { key = 'coding_lessons', name = 'Coding Lessons' },
    { key = 'symbol_training', name = 'Symbols' },
    { key = 'nvim_command_quiz', name = 'Command Quiz' },
  }

  for _, mode in ipairs(mode_names) do
    local s = player.stats[mode.key]
    if s and s.tasks_completed > 0 then
      local title = string.format('  %s %s', '◆', mode.name)
      table.insert(lines, title)
      local stat_line = string.format('    Accuracy: %-5.1f%%   Streak: %-4d   XP: %-6d', 
        s.total_accuracy, s.best_streak, s.total_xp_earned)
      table.insert(lines, stat_line)
      table.insert(lines, '')
    end
  end

  -- Empty state if no games played
  if player.total_sessions == 0 then
    table.insert(lines, '')
    table.insert(lines, center('No games played yet.', width))
    table.insert(lines, center('Go play some games!', width))
  end

  table.insert(lines, '')
  table.insert(lines, center('[ESC] Back', width))

  buffer_utils.set_content(buf, lines)
end

function M.setup_keymaps(buf, win, player)
  local opts = { buffer = buf, noremap = true, silent = true }
  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    require('typing_kata.ui.menu').show(player)
  end
  vim.keymap.set('n', 'q', close, opts)
  vim.keymap.set('n', '<Esc>', close, opts)
end

return M
