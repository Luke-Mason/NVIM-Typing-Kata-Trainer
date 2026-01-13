-- Player profile management (save/load)
local M = {}

local config = require('typing_kata.config')

-- Get player profile path
local function get_profile_path()
  local data_dir = config.current.data_dir
  vim.fn.mkdir(data_dir, 'p')  -- Create directory if it doesn't exist
  return data_dir .. '/player_profile.json'
end

-- Create a new player profile
function M.new_player(name)
  return {
    name = name or 'Player',
    current_xp = 0,
    current_rank = 0,
    created_at = os.date('!%Y-%m-%dT%H:%M:%S'),
    last_played = os.date('!%Y-%m-%dT%H:%M:%S'),
    total_sessions = 0,
    total_playtime = 0,  -- seconds

    -- Per-mode statistics
    stats = {
      custom_keybindings = M.new_mode_stats(),
      snake_apple = M.new_mode_stats(),
      symbol_training = M.new_mode_stats(),
      coding_lessons = M.new_mode_stats(),
      word_typing = M.new_mode_stats(),
      vim_motions = M.new_mode_stats(),
      comprehensive_keys = M.new_mode_stats(),
    },
  }
end

-- Create new mode stats structure
function M.new_mode_stats()
  return {
    tasks_completed = 0,
    total_accuracy = 0.0,
    average_speed = 0.0,
    best_streak = 0,
    total_time_played = 0,
    total_xp_earned = 0,
    extra_data = {},
  }
end

-- Load player profile from disk
function M.load()
  local profile_path = get_profile_path()
  local file = io.open(profile_path, 'r')

  if not file then
    -- No save file, create new player
    return M.new_player()
  end

  local content = file:read('*a')
  file:close()

  local ok, player = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('Failed to load player profile, creating new one', vim.log.levels.WARN)
    return M.new_player()
  end

  return player
end

-- Save player profile to disk
function M.save(player)
  player.last_played = os.date('!%Y-%m-%dT%H:%M:%S')

  local profile_path = get_profile_path()
  local file = io.open(profile_path, 'w')

  if not file then
    vim.notify('Failed to save player profile', vim.log.levels.ERROR)
    return false
  end

  local json = vim.json.encode(player)
  file:write(json)
  file:close()

  return true
end

-- Add XP to player
function M.add_xp(player, xp)
  player.current_xp = player.current_xp + xp

  -- Update rank
  local ranks = require('typing_kata.core.ranks')
  local rank = ranks.get_rank_by_xp(player.current_xp)
  player.current_rank = rank.id
end

-- Update player stats from session
function M.update_from_session(player, session)
  -- Get mode stats
  local mode_stats = player.stats[session.mode_name]
  if not mode_stats then
    mode_stats = M.new_mode_stats()
    player.stats[session.mode_name] = mode_stats
  end

  -- Update stats
  mode_stats.tasks_completed = mode_stats.tasks_completed + session.tasks_completed
  mode_stats.total_xp_earned = mode_stats.total_xp_earned + session.xp_earned
  mode_stats.total_time_played = mode_stats.total_time_played + require('typing_kata.core.session').get_duration(session)

  -- Update best streak
  if session.best_streak > mode_stats.best_streak then
    mode_stats.best_streak = session.best_streak
  end

  -- Update rolling accuracy
  local session_accuracy = require('typing_kata.core.session').calculate_accuracy(session)
  local total_tasks = mode_stats.tasks_completed
  if total_tasks > 0 then
    mode_stats.total_accuracy = ((mode_stats.total_accuracy * (total_tasks - 1)) + session_accuracy) / total_tasks
  else
    mode_stats.total_accuracy = session_accuracy
  end

  -- Update global player stats
  player.total_sessions = player.total_sessions + 1
  player.total_playtime = player.total_playtime + require('typing_kata.core.session').get_duration(session)

  -- Add XP
  M.add_xp(player, session.xp_earned)
end

-- Get mode stats (or create if doesn't exist)
function M.get_mode_stats(player, mode_name)
  if not player.stats[mode_name] then
    player.stats[mode_name] = M.new_mode_stats()
  end
  return player.stats[mode_name]
end

return M
