-- Base Quiz Mode: Shared logic for quiz-style games
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')

local BaseQuizMode = setmetatable({}, { __index = BaseMode })
BaseQuizMode.__index = BaseQuizMode

function BaseQuizMode:new(player, mode_name)
  local obj = BaseMode:new(player, mode_name)
  setmetatable(obj, { __index = self })

  obj.questions_per_session = 15
  obj.current_question_idx = 1
  obj.question_list = {}
  obj.current_question = nil
  obj.typed_answer = ""
  obj.show_answer = false

  return obj
end

-- Abstract: Return list of questions
function BaseQuizMode:get_questions()
  error(self.mode_name .. ': get_questions() must be implemented by subclass')
end

-- Abstract: Check if answer is correct
function BaseQuizMode:check_answer(typed, question)
  return typed == question.answer
end

function BaseQuizMode:setup()
  local all_questions = self:get_questions()

  -- Shuffle
  local shuffled = {}
  for i = 1, #all_questions do
    shuffled[i] = all_questions[i]
  end

  for i = #shuffled, 2, -1 do
    local j = math.random(i)
    shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
  end

  -- Take N questions
  for i = 1, math.min(self.questions_per_session, #shuffled) do
    table.insert(self.question_list, shuffled[i])
  end
end

function BaseQuizMode:generate_task()
  if self.current_question_idx > #self.question_list then
    self:exit()
    return
  end

  self.current_question = self.question_list[self.current_question_idx]
  self.typed_answer = ""
  self.show_answer = false
end

function BaseQuizMode:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function BaseQuizMode:setup_buffer_keymaps()
  BaseMode.setup_buffer_keymaps(self)

  vim.schedule(function()
    if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
      vim.cmd('startinsert')
    end
  end)

  local opts = { buffer = self.buffer, noremap = true, silent = true }

  -- Common character mapping
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

  -- Special keys
  vim.keymap.set('i', '<Space>', function() return self:handle_char(' ') end, opts)
  vim.keymap.set('i', '<BS>', function() return self:backspace() end, opts)
  vim.keymap.set('i', '<CR>', function() return self:submit() end, opts)
  vim.keymap.set('i', '<Tab>', function() return self:skip() end, opts)

  -- Ctrl/Alt/F-keys for quizzes
  self:setup_special_keys(opts)
end

function BaseQuizMode:setup_special_keys(opts)
  local ctrl_keys = 'abcdefghijklmnopqrstuvwxyz'
  for i = 1, #ctrl_keys do
    local letter = ctrl_keys:sub(i, i)
    vim.keymap.set('i', '<C-' .. letter .. '>', function() return self:handle_char('<C-' .. letter .. '>') end, opts)
    vim.keymap.set('i', '<A-' .. letter .. '>', function() return self:handle_char('<A-' .. letter .. '>') end, opts)
  end

  for i = 1, 12 do
    vim.keymap.set('i', '<F' .. i .. '>', function() return self:handle_char('<F' .. i .. '>') end, opts)
  end
  
  -- Arrows
  vim.keymap.set('i', '<Up>', function() return self:handle_char('<Up>') end, opts)
  vim.keymap.set('i', '<Down>', function() return self:handle_char('<Down>') end, opts)
  vim.keymap.set('i', '<Left>', function() return self:handle_char('<Left>') end, opts)
  vim.keymap.set('i', '<Right>', function() return self:handle_char('<Right>') end, opts)
  
  -- Ctrl+Arrows
  vim.keymap.set('i', '<C-Up>', function() return self:handle_char('<C-Up>') end, opts)
  vim.keymap.set('i', '<C-Down>', function() return self:handle_char('<C-Down>') end, opts)
end

function BaseQuizMode:handle_char(char)
  self.typed_answer = self.typed_answer .. char
  self:render()
  return ''
end

function BaseQuizMode:backspace()
  if #self.typed_answer > 0 then
    self.typed_answer = self.typed_answer:sub(1, -2)
    self:render()
  end
  return ''
end

function BaseQuizMode:skip()
  if not self.show_answer then
    self.show_answer = true
    self:render()
  else
    self.current_question_idx = self.current_question_idx + 1
    self:generate_task()
    self:render()
  end
  return ''
end

function BaseQuizMode:submit()
  local correct = self:check_answer(self.typed_answer, self.current_question)

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

function BaseQuizMode:calculate_xp()
  local base_xp = 20
  local accuracy = session.calculate_accuracy(self.session)
  return xp_module.calculate(base_xp, {
    accuracy = accuracy,
    streak = self.session.current_streak,
  })
end

function BaseQuizMode:update(key)
  return false
end

return BaseQuizMode
