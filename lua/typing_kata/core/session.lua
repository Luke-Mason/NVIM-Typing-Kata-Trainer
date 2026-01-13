-- Game session tracking
local M = {}

-- Create a new game session
function M.new(mode_name)
  return {
    mode_name = mode_name,
    start_time = os.time(),
    end_time = nil,

    -- Task tracking
    tasks_completed = 0,
    current_streak = 0,
    best_streak = 0,

    -- Keystroke tracking
    total_keystrokes = 0,
    correct_keystrokes = 0,
    error_count = 0,

    -- XP tracking
    xp_earned = 0,

    -- Mode-specific data (flexible storage)
    mode_data = {},
  }
end

-- Record a keystroke
function M.record_keystroke(session, correct)
  session.total_keystrokes = session.total_keystrokes + 1

  if correct then
    session.correct_keystrokes = session.correct_keystrokes + 1
  else
    session.error_count = session.error_count + 1
    session.current_streak = 0  -- Break streak on error
  end
end

-- Calculate current accuracy
function M.calculate_accuracy(session)
  if session.total_keystrokes == 0 then
    return 100
  end
  return (session.correct_keystrokes / session.total_keystrokes) * 100
end

-- Add task completion
function M.add_task_completion(session, xp)
  session.tasks_completed = session.tasks_completed + 1
  session.xp_earned = session.xp_earned + xp
end

-- Increment streak
function M.increment_streak(session)
  session.current_streak = session.current_streak + 1
  if session.current_streak > session.best_streak then
    session.best_streak = session.current_streak
  end
end

-- Break streak (reset to 0)
function M.break_streak(session)
  session.current_streak = 0
end

-- End session
function M.end_session(session)
  session.end_time = os.time()
  return session
end

-- Get session duration in seconds
function M.get_duration(session)
  local end_time = session.end_time or os.time()
  return end_time - session.start_time
end

-- Get session summary as string
function M.get_summary(session)
  local duration = M.get_duration(session)
  local accuracy = M.calculate_accuracy(session)

  local lines = {
    '========================================',
    '          SESSION COMPLETE',
    '========================================',
    '',
    'Mode: ' .. session.mode_name,
    'Tasks Completed: ' .. session.tasks_completed,
    'XP Earned: ' .. session.xp_earned,
    '',
    'Accuracy: ' .. string.format('%.1f%%', accuracy),
    'Best Streak: ' .. session.best_streak,
    'Duration: ' .. string.format('%dm %ds', math.floor(duration / 60), duration % 60),
    '',
    'Total Keystrokes: ' .. session.total_keystrokes,
    'Correct: ' .. session.correct_keystrokes,
    'Errors: ' .. session.error_count,
    '========================================',
  }

  return table.concat(lines, '\n')
end

return M
