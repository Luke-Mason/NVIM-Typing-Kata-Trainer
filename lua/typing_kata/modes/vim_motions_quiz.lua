-- Vim Motions Quiz: Given a task, type the correct vim motion sequence
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')

local VimMotionsQuiz = setmetatable({}, { __index = BaseMode })

-- Quiz questions: task description -> expected vim motion(s)
VimMotionsQuiz.QUESTIONS = {
  -- Basic motions
  {task = "Delete the current word", answer = "daw", alt_answers = {"diw"}},
  {task = "Change the text inside parentheses", answer = "ci(", alt_answers = {"ci)", "cib"}},
  {task = "Yank (copy) 5 words", answer = "y5w", alt_answers = {"5yw"}},
  {task = "Delete from cursor to end of line", answer = "d$", alt_answers = {"D"}},
  {task = "Go to line 42", answer = "42G", alt_answers = {"42gg", ":42"}},
  {task = "Delete everything inside quotes", answer = "di\"", alt_answers = {"di'"}},
  {task = "Visual select entire function block", answer = "va{", alt_answers = {"vaB", "va}"}},
  {task = "Jump to matching bracket", answer = "%"},
  {task = "Repeat last change", answer = "."},
  {task = "Delete 3 lines", answer = "d3j", alt_answers = {"3dd", "d2j"}},
  {task = "Change until end of word", answer = "ce", alt_answers = {"cw"}},
  {task = "Delete from cursor until semicolon", answer = "df;", alt_answers = {"dt;"}},
  {task = "Yank from cursor to beginning of line", answer = "y0"},
  {task = "Go to first non-blank character of line", answer = "^", alt_answers = {"_"}},
  {task = "Delete character under cursor", answer = "x", alt_answers = {"dl"}},
  {task = "Insert at beginning of line", answer = "I"},
  {task = "Append at end of line", answer = "A"},
  {task = "Open new line below and insert", answer = "o"},
  {task = "Open new line above and insert", answer = "O"},
  {task = "Replace character under cursor", answer = "r"},

  -- Search and navigation
  {task = "Search forward for 'foo'", answer = "/foo"},
  {task = "Search backward for 'bar'", answer = "?bar"},
  {task = "Jump to next search result", answer = "n"},
  {task = "Jump to previous search result", answer = "N"},
  {task = "Delete current line", answer = "dd"},
  {task = "Copy (yank) current line", answer = "yy"},
  {task = "Paste after cursor", answer = "p"},
  {task = "Paste before cursor", answer = "P"},
  {task = "Select all text in file", answer = "ggVG"},
  {task = "Jump to beginning of file", answer = "gg"},
  {task = "Jump to end of file", answer = "G"},
  {task = "Delete word under cursor", answer = "daw", alt_answers = {"diw"}},
  {task = "Change word under cursor", answer = "ciw", alt_answers = {"caw"}},
  {task = "Visual select inside brackets", answer = "vi(", alt_answers = {"vi)", "vib"}},
  {task = "Delete everything in this function", answer = "di{", alt_answers = {"di}", "diB"}},

  -- Advanced
  {task = "Undo last change", answer = "u"},
  {task = "Redo last undone change", answer = "<C-r>"},
  {task = "Scroll half page down", answer = "<C-d>"},
  {task = "Scroll half page up", answer = "<C-u>"},
  {task = "Scroll full page down", answer = "<C-f>"},
  {task = "Scroll full page up", answer = "<C-b>"},
  {task = "Go to definition (LSP)", answer = "gd"},
  {task = "Format current line", answer = "=="},
  {task = "Indent current line", answer = ">>"},
  {task = "Unindent current line", answer = "<<"},
  {task = "Join current line with next", answer = "J"},
  {task = "Change case of character", answer = "~"},
  {task = "Mark current position as 'a'", answer = "ma"},
  {task = "Jump to mark 'a'", answer = "'a", alt_answers = {"`a"}},
  {task = "Record macro to register 'q'", answer = "qq"},
  {task = "Play macro from register 'q'", answer = "@q"},
  {task = "Repeat last find/till command", answer = ";"},
  {task = "Reverse last find/till command", answer = ","},

  -- Vim commands
  {task = "Search and replace in whole file", answer = ":%s/", alt_answers = {":%s"}},
  {task = "Substitute on current line", answer = ":s/", alt_answers = {":s"}},
  {task = "Save file", answer = ":w", alt_answers = {":write"}},
  {task = "Quit vim", answer = ":q", alt_answers = {":quit"}},
  {task = "Save and quit", answer = ":wq", alt_answers = {"ZZ", ":x", ":exit"}},
  {task = "Force quit without saving", answer = ":q!", alt_answers = {"ZQ", ":quit!"}},
  {task = "Show line numbers", answer = ":set number", alt_answers = {":set nu"}},
  {task = "Show relative line numbers", answer = ":set relativenumber", alt_answers = {":set rnu"}},
  {task = "Enable paste mode", answer = ":set paste"},
  {task = "Disable paste mode", answer = ":set nopaste"},
  {task = "Toggle line wrapping", answer = ":set wrap!", alt_answers = {":set nowrap"}},
  {task = "Set tab width to 4 spaces", answer = ":set tabstop=4", alt_answers = {":set ts=4"}},
  {task = "Set shift width to 2", answer = ":set shiftwidth=2", alt_answers = {":set sw=2"}},
  {task = "Enable spell checking", answer = ":set spell"},
  {task = "Disable spell checking", answer = ":set nospell"},
  {task = "Show whitespace characters", answer = ":set list"},
  {task = "Hide whitespace characters", answer = ":set nolist"},
  {task = "Reload file from disk", answer = ":e!", alt_answers = {":edit!"}},
  {task = "Open new horizontal split", answer = ":split", alt_answers = {":sp"}},
  {task = "Open new vertical split", answer = ":vsplit", alt_answers = {":vsp", ":vs"}},
  {task = "Close current window", answer = ":close", alt_answers = {":clo"}},
  {task = "Make current window only window", answer = ":only", alt_answers = {":on"}},
  {task = "Set syntax highlighting to python", answer = ":set syntax=python", alt_answers = {":set syn=python"}},
  {task = "Turn off search highlighting", answer = ":noh", alt_answers = {":nohlsearch"}},
  {task = "Show current file path", answer = ":echo @%", alt_answers = {":f", ":file"}},
  {task = "Open file under cursor", answer = "gf"},
  {task = "Jump back to previous position", answer = "<C-o>"},
  {task = "Jump forward to next position", answer = "<C-i>"},
  {task = "Increment number under cursor", answer = "<C-a>"},
  {task = "Decrement number under cursor", answer = "<C-x>"},
  {task = "Go to beginning of file", answer = "gg", alt_answers = {":1"}},
  {task = "Go to end of file", answer = "G", alt_answers = {":$"}},
  {task = "Move cursor to top of screen", answer = "H"},
  {task = "Move cursor to middle of screen", answer = "M"},
  {task = "Move cursor to bottom of screen", answer = "L"},
  {task = "Center screen on cursor", answer = "zz"},
  {task = "Scroll screen so cursor is at top", answer = "zt"},
  {task = "Scroll screen so cursor is at bottom", answer = "zb"},
  {task = "Delete to end of line", answer = "D", alt_answers = {"d$"}},
  {task = "Change to end of line", answer = "C", alt_answers = {"c$"}},
  {task = "Yank to end of line", answer = "Y", alt_answers = {"y$", "yy"}},
}

function VimMotionsQuiz:new(player)
  local obj = BaseMode:new(player, 'vim_motions_quiz')
  setmetatable(obj, { __index = self })

  obj.questions_per_session = 15
  obj.current_question_idx = 1
  obj.question_list = {}
  obj.current_question = nil
  obj.typed_answer = ""
  obj.show_answer = false

  return obj
end

function VimMotionsQuiz:setup()
  -- Shuffle questions using Fisher-Yates algorithm
  local shuffled = {}
  for i = 1, #self.QUESTIONS do
    shuffled[i] = self.QUESTIONS[i]
  end

  for i = #shuffled, 2, -1 do
    local j = math.random(i)
    shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
  end

  -- Take first N questions
  for i = 1, math.min(self.questions_per_session, #shuffled) do
    table.insert(self.question_list, shuffled[i])
  end
end

function VimMotionsQuiz:generate_task()
  if self.current_question_idx > #self.question_list then
    self:exit()
    return
  end

  self.current_question = self.question_list[self.current_question_idx]
  self.typed_answer = ""
  self.show_answer = false
end

function VimMotionsQuiz:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function VimMotionsQuiz:setup_buffer_keymaps()
  BaseMode.setup_buffer_keymaps(self)

  vim.schedule(function()
    if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
      vim.cmd('startinsert')
    end
  end)

  local opts = { buffer = self.buffer, noremap = true, silent = true }

  local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local symbols = '`~!@#$%^&*()-_=+[{]}\\|;:\'",<.>/?'

  for i = 1, #chars do
    local char = chars:sub(i, i)
    vim.keymap.set('i', char, function() return self:handle_char(char) end, opts)
  end

  for i = 1, #symbols do
    local char = symbols:sub(i, i)
    vim.keymap.set('i', char, function() return self:handle_char(char) end, opts)
  end

  vim.keymap.set('i', '<Space>', function() return self:handle_char(' ') end, opts)
  vim.keymap.set('i', '<BS>', function() return self:backspace() end, opts)
  vim.keymap.set('i', '<CR>', function() return self:submit() end, opts)
  vim.keymap.set('i', '<Tab>', function() return self:skip() end, opts)

  -- Map Ctrl combinations to insert their notation
  local ctrl_keys = 'abcdefghijklmnopqrstuvwxyz'
  for i = 1, #ctrl_keys do
    local letter = ctrl_keys:sub(i, i)
    vim.keymap.set('i', '<C-' .. letter .. '>', function()
      return self:handle_char('<C-' .. letter .. '>')
    end, opts)
  end

  -- Map Alt combinations
  for i = 1, #ctrl_keys do
    local letter = ctrl_keys:sub(i, i)
    vim.keymap.set('i', '<A-' .. letter .. '>', function()
      return self:handle_char('<A-' .. letter .. '>')
    end, opts)
  end

  -- Map F-keys
  for i = 1, 12 do
    vim.keymap.set('i', '<F' .. i .. '>', function()
      return self:handle_char('<F' .. i .. '>')
    end, opts)
  end
end

function VimMotionsQuiz:handle_char(char)
  self.typed_answer = self.typed_answer .. char
  self:render()
  return ''
end

function VimMotionsQuiz:backspace()
  if #self.typed_answer > 0 then
    self.typed_answer = self.typed_answer:sub(1, -2)
    self:render()
  end
  return ''
end

function VimMotionsQuiz:submit()
  local correct = false

  -- Check if answer matches
  if self.typed_answer == self.current_question.answer then
    correct = true
  elseif self.current_question.alt_answers then
    for _, alt in ipairs(self.current_question.alt_answers) do
      if self.typed_answer == alt then
        correct = true
        break
      end
    end
  end

  if correct then
    session.record_keystroke(self.session, true)
    session.increment_streak(self.session)
    vim.notify('✓ Correct!', vim.log.levels.INFO)

    local xp = self:calculate_xp()
    session.add_task_completion(self.session, xp)

    vim.defer_fn(function()
      if self.is_running then
        self.current_question_idx = self.current_question_idx + 1
        self:generate_task()
        self:render()
      end
    end, 800)
  else
    session.record_keystroke(self.session, false)
    session.break_streak(self.session)
    vim.notify('✗ Wrong! Correct answer: ' .. self.current_question.answer, vim.log.levels.WARN)

    -- Show the answer visually in the UI
    vim.defer_fn(function()
      if self.is_running then
        self.show_answer = true
        self.typed_answer = ""
        self:render()
      end
    end, 1500)
  end

  return ''
end

function VimMotionsQuiz:skip()
  if not self.show_answer then
    -- First press: show answer
    self.show_answer = true
    self:render()
  else
    -- Second press: move to next question
    self.current_question_idx = self.current_question_idx + 1
    self:generate_task()
    self:render()
  end
  return ''
end

function VimMotionsQuiz:update(key)
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

  -- Add consistent controls legend
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

function VimMotionsQuiz:calculate_xp()
  local base_xp = 20
  local accuracy = session.calculate_accuracy(self.session)

  return xp_module.calculate(base_xp, {
    accuracy = accuracy,
    streak = self.session.current_streak,
  })
end

return VimMotionsQuiz
