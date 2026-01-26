-- Neovim Command Quiz: Given a plugin command/tool, type your keybinding
local BaseQuizMode = require('typing_kata.modes.base_quiz_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local keymap_parser = require('typing_kata.core.keymap_parser')
local nvim_commands = require('typing_kata.core.data.nvim_commands')

local NvimCommandQuiz = setmetatable({}, { __index = BaseQuizMode })

function NvimCommandQuiz:new(player)
  local obj = BaseQuizMode:new(player, 'nvim_command_quiz')
  setmetatable(obj, { __index = self })
  return obj
end

function NvimCommandQuiz:get_questions()
  -- Detect user keymaps and override answers
  local questions = {}
  local detected_count = 0
  
  for _, cmd in ipairs(nvim_commands.commands) do
    local q = vim.deepcopy(cmd)
    
    if q.command_key then
      local user_keymap = keymap_parser.get_keymap_for_command(q.command_key, q.answer)
      if user_keymap ~= q.answer then
        q.answer = user_keymap
        q.is_custom = true
        detected_count = detected_count + 1
      end
    end
    
    table.insert(questions, q)
  end

  if detected_count > 0 then
    vim.notify(string.format('✓ Detected %d/%d custom keymaps!', detected_count, #questions), vim.log.levels.INFO)
  end
  
  return questions
end

function NvimCommandQuiz:check_answer(typed, question)
  return typed == question.answer
end

function NvimCommandQuiz:render()
  local lines = {}

  table.insert(lines, '')
  table.insert(lines, '═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '                     🔧 NEOVIM COMMAND QUIZ')
  table.insert(lines, '═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '')
  table.insert(lines, '                     💡 SPACE = <leader>')
  table.insert(lines, '                     (Type: <leader>ff for leader+f+f)')
  table.insert(lines, '')
  table.insert(lines, string.format('                     Questions Completed: %d',
    self.questions_completed))
  table.insert(lines, '')
  table.insert(lines, '───────────────────────────────────────────────────────────────────')
  table.insert(lines, '')

  if self.current_question then
    table.insert(lines, '  COMMAND:')
    table.insert(lines, '  ' .. self.current_question.desc)
    local plugin_line = '  [' .. self.current_question.plugin .. ']'
    if self.current_question.is_custom then
      plugin_line = plugin_line .. ' 🔍 Detected from your config'
    end
    table.insert(lines, plugin_line)
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '  YOUR KEYBINDING:')
    table.insert(lines, '  > ' .. self.typed_answer .. '_')
    table.insert(lines, '')

    if self.show_answer then
      table.insert(lines, '')
      table.insert(lines, '  ✓ CORRECT ANSWER: ' .. self.current_question.answer)
      if self.current_question.is_custom then
        table.insert(lines, '    (From your Neovim config)')
      end
      table.insert(lines, '')
    end
  end

  table.insert(lines, '')
  table.insert(lines, '───────────────────────────────────────────────────────────────────')
  table.insert(lines, string.format('  Accuracy: %.1f%%  |  Streak: %d  |  XP: %d',
    session.calculate_accuracy(self.session), self.session.current_streak, self.session.xp_earned))
  table.insert(lines, '───────────────────────────────────────────────────────────────────')

  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type keybinding literally (e.g., <leader>ff or <C-u>)'},
    {key = 'ENTER', desc = 'Submit answer'},
    {key = 'TAB', desc = 'Show answer / Next question'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
end

return NvimCommandQuiz
