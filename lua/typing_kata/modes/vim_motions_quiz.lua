-- Vim Motions Quiz: Given a task, type the correct vim motion sequence
local BaseQuizMode = require('typing_kata.modes.base_quiz_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local quiz_questions = require('typing_kata.core.data.quiz_questions')

local VimMotionsQuiz = setmetatable({}, { __index = BaseQuizMode })

function VimMotionsQuiz:new(player)
  local obj = BaseQuizMode:new(player, 'vim_motions_quiz')
  setmetatable(obj, { __index = self })
  return obj
end

function VimMotionsQuiz:get_questions()
  return quiz_questions.questions
end

function VimMotionsQuiz:check_answer(typed, question)
  if typed == question.answer then
    return true
  end
  
  if question.alt_answers then
    for _, alt in ipairs(question.alt_answers) do
      if typed == alt then
        return true
      end
    end
  end
  
  return false
end

function VimMotionsQuiz:render()
  local lines = {}

  table.insert(lines, '')
  table.insert(lines, '═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '                       🎯 VIM MOTIONS QUIZ')
  table.insert(lines, '═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '')
  table.insert(lines, '                     💡 SPACE = <leader>')
  table.insert(lines, '                     (Type: <leader>rn for leader+r+n)')
  table.insert(lines, '')
  table.insert(lines, string.format('                     Question %d of %d',
    self.current_question_idx, self.questions_per_session))
  table.insert(lines, '')
  table.insert(lines, '───────────────────────────────────────────────────────────────────')
  table.insert(lines, '')

  if self.current_question then
    table.insert(lines, '  TASK:')
    table.insert(lines, '  ' .. self.current_question.task)
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '  YOUR ANSWER:')
    table.insert(lines, '  > ' .. self.typed_answer .. '_')
    table.insert(lines, '')

    if self.show_answer then
      table.insert(lines, '')
      table.insert(lines, '  ✓ CORRECT ANSWER: ' .. self.current_question.answer)
      if self.current_question.alt_answers then
        table.insert(lines, '    (Also accepts: ' .. table.concat(self.current_question.alt_answers, ', ') .. ')')
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
    {key = 'Type', desc = 'Type vim motion literally (e.g., <C-u> or <leader>rn)'},
    {key = 'ENTER', desc = 'Submit answer'},
    {key = 'TAB', desc = 'Show answer / Next question'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
end

return VimMotionsQuiz
