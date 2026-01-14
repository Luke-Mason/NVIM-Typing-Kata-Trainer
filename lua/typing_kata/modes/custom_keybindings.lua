-- Custom Keybindings Mode: Practice user's actual keybindings
local BaseQuizMode = require('typing_kata.modes.base_quiz_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')

local CustomKeybindings = setmetatable({}, { __index = BaseQuizMode })

function CustomKeybindings:new(player)
  local obj = BaseQuizMode:new(player, 'custom_keybindings')
  setmetatable(obj, { __index = self })
  return obj
end

function CustomKeybindings:get_questions()
  local keymaps = vim.api.nvim_get_keymap('n')
  local questions = {}
  
  for _, map in ipairs(keymaps) do
    -- Only use keymaps that have a description or a clear command
    if map.desc or (map.rhs and map.rhs ~= '') then
      local task_desc = map.desc
      if not task_desc then
        task_desc = "Command: " .. map.rhs
      end
      
      -- Filter out internal plugin maps (often start with <Plug>)
      if not map.lhs:lower():match("^<plug>") then
         table.insert(questions, {
           task = task_desc,
           answer = map.lhs,
           rhs = map.rhs
         })
      end
    end
  end
  
  if #questions == 0 then
    -- Fallback if no keys found
    table.insert(questions, {
       task = "No custom keybindings found with descriptions! Define keys with {desc='...'} in vim.keymap.set",
       answer = "<CR>"
    })
  end
  
  return questions
end

function CustomKeybindings:check_answer(typed, question)
  -- Case insensitive check? Or strict? 
  -- Keybindings are case sensitive usually.
  return typed == question.answer
end

function CustomKeybindings:render()
  local lines = {}

  table.insert(lines, '')
  table.insert(lines, '═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '                     🎯 CUSTOM KEYBINDINGS QUIZ')
  table.insert(lines, '═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '')
  table.insert(lines, '                     Practicing your ACTUAL configuration')
  table.insert(lines, '')
  table.insert(lines, string.format('                     Question %d of %d',
    self.current_question_idx, self.questions_per_session))
  table.insert(lines, '')
  table.insert(lines, '───────────────────────────────────────────────────────────────────')
  table.insert(lines, '')

  if self.current_question then
    table.insert(lines, '  TASK/DESC:')
    table.insert(lines, '  ' .. self.current_question.task)
    if self.current_question.rhs then
       table.insert(lines, '  (Executes: ' .. self.current_question.rhs .. ')')
    end
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '  YOUR KEYBINDING:')
    table.insert(lines, '  > ' .. self.typed_answer .. '_')
    table.insert(lines, '')

    if self.show_answer then
      table.insert(lines, '')
      table.insert(lines, '  ✓ CORRECT ANSWER: ' .. self.current_question.answer)
      table.insert(lines, '')
    end
  end

  table.insert(lines, '')
  table.insert(lines, '───────────────────────────────────────────────────────────────────')
  table.insert(lines, string.format('  Accuracy: %.1f%%  |  Streak: %d  |  XP: %d',
    session.calculate_accuracy(self.session), self.session.current_streak, self.session.xp_earned))
  table.insert(lines, '───────────────────────────────────────────────────────────────────')

  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type your keybinding'},
    {key = 'ENTER', desc = 'Submit answer'},
    {key = 'TAB', desc = 'Show answer / Next question'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
end

return CustomKeybindings
