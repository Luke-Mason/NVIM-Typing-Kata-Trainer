-- Coding Lessons Mode: Type real code snippets
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')

local CodingLessons = setmetatable({}, { __index = BaseMode })

function CodingLessons:new(player)
  local obj = BaseMode:new(player, 'coding_lessons')
  setmetatable(obj, { __index = self })
  return obj
end

function CodingLessons:setup()
  -- TODO: Load code snippets or use AI generation
end

function CodingLessons:update(key)
  return false
end

function CodingLessons:generate_task()
  -- TODO: Generate code typing task
end

function CodingLessons:render()
  local lines = {
    '',
    '     💻 CODING LESSONS',
    '     =================',
    '',
    '     This mode is not yet implemented.',
    '     It will provide code snippets to type',
    '     character-by-character for WPM training.',
    '',
    '     Press ESC to return to menu',
    '',
  }
  buffer_utils.set_content(self.buffer, lines)
end

function CodingLessons:calculate_xp()
  return 0
end

return CodingLessons
