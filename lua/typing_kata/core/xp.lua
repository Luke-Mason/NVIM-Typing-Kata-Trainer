-- XP calculation system
local M = {}

-- Calculate total XP with bonuses
-- @param base_xp: Base XP for the task
-- @param opts: Table with optional bonus parameters
--   - accuracy: Accuracy percentage (0-100)
--   - wpm: Words per minute (for WPM modes)
--   - speed_factor: Generic speed factor (0-1)
--   - streak: Current streak count
--   - efficiency: Efficiency ratio (0-1, for Snake Apple)
function M.calculate(base_xp, opts)
  opts = opts or {}

  local total_xp = base_xp

  -- Accuracy bonus (0-10 XP)
  if opts.accuracy then
    local accuracy_bonus = (opts.accuracy / 100) * 10
    total_xp = total_xp + accuracy_bonus
  end

  -- Speed bonus (0-5 XP)
  local speed_factor = 0
  if opts.wpm then
    -- WPM-based speed factor (80+ WPM = max bonus)
    speed_factor = math.min(opts.wpm / 80, 1.0)
  elseif opts.efficiency then
    -- Efficiency-based (for Snake Apple)
    speed_factor = opts.efficiency
  elseif opts.speed_factor then
    -- Generic speed factor
    speed_factor = opts.speed_factor
  end

  local speed_bonus = math.min(speed_factor * 5, 5)
  total_xp = total_xp + speed_bonus

  -- Streak bonus (0-15 XP, capped)
  if opts.streak then
    local streak_bonus = math.min(opts.streak * 0.5, 15)
    total_xp = total_xp + streak_bonus
  end

  return math.floor(total_xp + 0.5)  -- Round to nearest integer
end

-- Calculate WPM from characters and time
-- @param chars_typed: Number of characters typed
-- @param time_seconds: Time in seconds
function M.calculate_wpm(chars_typed, time_seconds)
  if time_seconds == 0 then
    return 0
  end

  local minutes = time_seconds / 60
  local words = chars_typed / 5  -- Standard: 5 chars = 1 word
  return words / minutes
end

-- Calculate accuracy percentage
-- @param correct: Number of correct keystrokes
-- @param total: Total keystrokes
function M.calculate_accuracy(correct, total)
  if total == 0 then
    return 100
  end
  return (correct / total) * 100
end

return M
