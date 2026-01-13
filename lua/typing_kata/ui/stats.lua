-- Stats display screen
local M = {}

local buffer_utils = require('typing_kata.ui.buffer')
local ranks = require('typing_kata.core.ranks')
local config = require('typing_kata.config')

-- Format time in hours, minutes
local function format_time(seconds)
  local hours = math.floor(seconds / 3600)
  local mins = math.floor((seconds % 3600) / 60)

  if hours > 0 then
    return string.format('%dh %dm', hours, mins)
  else
    return string.format('%dm', mins)
  end
end

-- Show stats screen
function M.show(player)
  -- Create buffer
  local buf = buffer_utils.create_scratch_buffer('Typing Kata Stats')

  -- Render stats
  M.render_stats(buf, player)

  -- Create floating window
  local ui_config = config.current.ui
  local win = buffer_utils.create_floating_window(buf, {
    width = ui_config.menu_size.width,
    height = ui_config.menu_size.height,
    position = ui_config.menu_position,
    border = ui_config.border,
    title = ' STATS & PROGRESS ',
  })

  if not win then
    vim.notify('Failed to create stats window', vim.log.levels.ERROR)
    return
  end

  -- Setup keymaps
  M.setup_keymaps(buf, win, player)
end

function M.render_stats(buf, player)
  local rank = ranks.get_rank_by_xp(player.current_xp)
  local progress = ranks.progress_to_next_rank(player.current_xp)

  local next_rank_id = rank.id + 1
  local next_rank = nil
  if next_rank_id < 100 then
    next_rank = ranks.get_rank_by_id(next_rank_id)
  end

  local lines = {
    '',
    '          TYPING KATA STATS & PROGRESS',
    '          ===============================',
    '',
    string.format('     Player: %s', player.name),
    string.format('     Rank: %s %s (Level %d)', rank.symbol, rank.name, rank.id + 1),
    string.format('     Current XP: %d', player.current_xp),
    '',
  }

  if next_rank then
    table.insert(lines, string.format('     Next Rank: %s %s', next_rank.symbol, next_rank.name))
    table.insert(lines, string.format('     Progress: %.1f%% (%d XP needed)', progress, next_rank.xp_required - player.current_xp))
    table.insert(lines, '')
  else
    table.insert(lines, '     MAX RANK ACHIEVED!')
    table.insert(lines, '')
  end

  -- Overall stats
  table.insert(lines, '     OVERALL STATS')
  table.insert(lines, '     ─────────────')
  table.insert(lines, string.format('     Total Sessions: %d', player.total_sessions))
  table.insert(lines, string.format('     Total Playtime: %s', format_time(player.total_playtime)))
  table.insert(lines, '')

  -- Per-mode stats
  table.insert(lines, '     MODE STATISTICS')
  table.insert(lines, '     ───────────────')

  local mode_names = {
    { key = 'custom_keybindings', name = '🎯 Custom Keybindings' },
    { key = 'snake_apple', name = '🐍 Snake Apple' },
    { key = 'symbol_training', name = '🔣 Symbol Training' },
    { key = 'coding_lessons', name = '💻 Coding Lessons' },
    { key = 'word_typing', name = '📝 Word Typing' },
    { key = 'vim_motions', name = '⚡ Vim Motions' },
    { key = 'comprehensive_keys', name = '⌨️  Comprehensive Keys' },
  }

  for _, mode_info in ipairs(mode_names) do
    local mode_stats = player.stats[mode_info.key]
    if mode_stats and mode_stats.tasks_completed > 0 then
      table.insert(lines, '')
      table.insert(lines, '     ' .. mode_info.name)
      table.insert(lines, string.format('       Tasks: %d | Accuracy: %.1f%%',
        mode_stats.tasks_completed, mode_stats.total_accuracy))
      table.insert(lines, string.format('       Best Streak: %d | XP: %d | Time: %s',
        mode_stats.best_streak, mode_stats.total_xp_earned, format_time(mode_stats.total_time_played)))
    end
  end

  table.insert(lines, '')
  table.insert(lines, '')
  table.insert(lines, '     Press ESC or q to return to menu')
  table.insert(lines, '')

  buffer_utils.set_content(buf, lines)
end

function M.setup_keymaps(buf, win, player)
  local opts = { buffer = buf, noremap = true, silent = true }

  local function go_back()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    require('typing_kata.ui.menu').show(player)
  end

  vim.keymap.set('n', 'q', go_back, opts)
  vim.keymap.set('n', '<Esc>', go_back, opts)
end

return M
