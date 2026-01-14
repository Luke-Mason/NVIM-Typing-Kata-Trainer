-- Comprehensive Keys Mode: Practice all keyboard keys
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')
local typing_display = require('typing_kata.ui.typing_display')

local ComprehensiveKeys = setmetatable({}, { __index = BaseMode })

function ComprehensiveKeys:new(player)
  local obj = BaseMode:new(player, 'comprehensive_keys')
  setmetatable(obj, { __index = self })

  obj.chars_per_session = 100
  obj.target_text = ''
  obj.current_char_idx = 0
  obj.errors = {}
  obj.start_time = nil

  return obj
end

function ComprehensiveKeys:setup()
  self.start_time = os.time()
end

function ComprehensiveKeys:generate_task()
  local chars = {}
  -- ASCII 33 (!) to 126 (~)
  for i = 1, self.chars_per_session do
    local byte = math.random(33, 126)
    table.insert(chars, string.char(byte))
  end

  -- Join with spaces occasionally to make it readable, or just random stream?
  -- Let's do groups of 5
  local text_parts = {}
  local current_part = ""
  for i, char in ipairs(chars) do
    current_part = current_part .. char
    if i % 5 == 0 then
      table.insert(text_parts, current_part)
      current_part = ""
    end
  end
  if #current_part > 0 then table.insert(text_parts, current_part) end
  
  self.target_text = table.concat(text_parts, " ")
  self.current_char_idx = 0
  self.errors = {}
end

function ComprehensiveKeys:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function ComprehensiveKeys:setup_buffer_keymaps()
  BaseMode.setup_buffer_keymaps(self)

  vim.schedule(function()
    if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
      vim.cmd('startinsert')
    end
  end)

  local opts = { buffer = self.buffer, noremap = true, silent = true }

  -- Map all printable characters
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
end

function ComprehensiveKeys:handle_char(char)
  if self.current_char_idx >= #self.target_text then
    return ''
  end

  local expected_char = self.target_text:sub(self.current_char_idx + 1, self.current_char_idx + 1)

  if char == expected_char then
    self.current_char_idx = self.current_char_idx + 1
    session.record_keystroke(self.session, true)
    self.errors[self.current_char_idx] = nil
  else
    self.current_char_idx = self.current_char_idx + 1
    self.errors[self.current_char_idx] = true
    session.record_keystroke(self.session, false)
    session.break_streak(self.session)
  end

  if self.current_char_idx >= #self.target_text then
    local xp = self:calculate_xp()
    session.add_task_completion(self.session, xp)
    
    vim.defer_fn(function()
      if self.is_running then
        self:exit()
      end
    end, 500)
  end

  self:render()
  return ''
end

function ComprehensiveKeys:backspace()
  if self.current_char_idx > 0 then
    self.current_char_idx = self.current_char_idx - 1
    self:render()
  end
  return ''
end

function ComprehensiveKeys:update(key)
  return false
end

function ComprehensiveKeys:render()
  local lines = {}

  table.insert(lines, '')
  table.insert(lines, '          ⌨️  COMPREHENSIVE KEYS')
  table.insert(lines, '          =====================')
  table.insert(lines, '')

  local progress = math.floor((self.current_char_idx / #self.target_text) * 100)
  table.insert(lines, string.format('     Progress: %d%% (%d/%d chars)',
    progress, self.current_char_idx, #self.target_text))
  table.insert(lines, '')
  table.insert(lines, '')

  local display_section = typing_display.render_section(
    self.target_text,
    self.current_char_idx,
    self.errors,
    nil
  )

  local current_line_count = #lines
  for _, line in ipairs(display_section.lines) do
    table.insert(lines, line)
  end

  table.insert(lines, '')

  local accuracy = session.calculate_accuracy(self.session)
  table.insert(lines, string.format('     Accuracy: %.1f%%', accuracy))
  table.insert(lines, string.format('     Streak: %d', self.session.current_streak))
  table.insert(lines, string.format('     XP Earned: %d', self.session.xp_earned))
  table.insert(lines, '')

  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type the characters as they appear'},
    {key = 'BACKSPACE', desc = 'Delete last character'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
  local total_offset = current_line_count + display_section.highlight_line_offset
  typing_display.apply_highlights(self.buffer, display_section.highlights, total_offset)
end

function ComprehensiveKeys:calculate_xp()
  local base_xp = 150
  local accuracy = session.calculate_accuracy(self.session)
  return xp_module.calculate(base_xp, {
    accuracy = accuracy,
    streak = self.session.current_streak,
  })
end

return ComprehensiveKeys
