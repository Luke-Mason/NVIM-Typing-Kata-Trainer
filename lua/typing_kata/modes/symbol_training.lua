-- Symbol Training Mode: Practice special characters and symbols
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')
local typing_display = require('typing_kata.ui.typing_display')
local symbols_data = require('typing_kata.core.data.symbols')

local SymbolTraining = setmetatable({}, { __index = BaseMode })

function SymbolTraining:new(player)
  local obj = BaseMode:new(player, 'symbol_training')
  setmetatable(obj, { __index = self })

  obj.symbols_per_session = 100  -- More symbols for continuous flow
  obj.target_text = ''  -- Full symbol sequence
  obj.current_char_idx = 0  -- Current position in target_text
  obj.errors = {}  -- Track error positions
  obj.start_time = nil

  return obj
end

function SymbolTraining:setup()
  self.start_time = os.time()
end

function SymbolTraining:generate_task()
  -- Generate a continuous stream of symbols with spaces between them
  local symbols = {}
  local symbol_list = symbols_data.symbols
  
  for i = 1, self.symbols_per_session do
    local symbol = symbol_list[math.random(#symbol_list)]
    table.insert(symbols, symbol)
  end

  -- Join with spaces for easier typing
  self.target_text = table.concat(symbols, ' ')
  self.current_char_idx = 0
  self.errors = {}
end

function SymbolTraining:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function SymbolTraining:setup_buffer_keymaps()
  BaseMode.setup_buffer_keymaps(self)

  -- Enter insert mode automatically
  vim.schedule(function()
    if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
      vim.cmd('startinsert')
    end
  end)

  -- Capture character input in insert mode
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

  -- Space key
  vim.keymap.set('i', '<Space>', function() return self:handle_char(' ') end, opts)

  -- Backspace
  vim.keymap.set('i', '<BS>', function() return self:backspace() end, opts)
end

function SymbolTraining:handle_char(char)
  if self.current_char_idx >= #self.target_text then
    return ''  -- Already finished
  end

  local expected_char = self.target_text:sub(self.current_char_idx + 1, self.current_char_idx + 1)

  if char == expected_char then
    self.current_char_idx = self.current_char_idx + 1
    session.record_keystroke(self.session, true)
    self.errors[self.current_char_idx] = nil  -- Clear error if corrected
  else
    -- Wrong character
    self.current_char_idx = self.current_char_idx + 1
    self.errors[self.current_char_idx] = true
    session.record_keystroke(self.session, false)
    session.break_streak(self.session)
  end

  -- Check if completed
  if self.current_char_idx >= #self.target_text then
    local xp = self:calculate_xp()
    session.add_task_completion(self.session, xp)

    -- Small delay then exit
    vim.defer_fn(function()
      if self.is_running then
        self:exit()
      end
    end, 500)
  end

  self:render()
  return ''  -- Don't actually insert the character
end

function SymbolTraining:backspace()
  if self.current_char_idx > 0 then
    self.current_char_idx = self.current_char_idx - 1
    self:render()
  end
  return ''
end

function SymbolTraining:update(key)
  -- Not used in this mode (we handle input directly)
  return false
end

function SymbolTraining:render()
  local lines = {}

  -- Title
  table.insert(lines, '')
  table.insert(lines, '          🔣 SYMBOL TRAINING')
  table.insert(lines, '          ==================')
  table.insert(lines, '')

  -- Progress
  local progress = math.floor((self.current_char_idx / #self.target_text) * 100)
  table.insert(lines, string.format('     Progress: %d%% (%d/%d chars)',
    progress, self.current_char_idx, #self.target_text))
  table.insert(lines, '')
  table.insert(lines, '')

  -- Typing display using monkeytype-style component
  local display_section = typing_display.render_section(
    self.target_text,
    self.current_char_idx,
    self.errors,
    nil  -- No additional title
  )

  -- Add typing display lines
  local current_line_count = #lines
  for _, line in ipairs(display_section.lines) do
    table.insert(lines, line)
  end

  table.insert(lines, '')

  -- Stats
  local accuracy = session.calculate_accuracy(self.session)
  table.insert(lines, string.format('     Accuracy: %.1f%%', accuracy))
  table.insert(lines, string.format('     Streak: %d', self.session.current_streak))
  table.insert(lines, string.format('     XP Earned: %d', self.session.xp_earned))
  table.insert(lines, '')

  -- Add consistent controls legend
  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type the symbols as they appear (cursor stays in middle)'},
    {key = 'BACKSPACE', desc = 'Delete last character'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)

  -- Apply highlights
  -- highlight_line_offset is internal to section, we must add current_line_count (where section started)
  local total_offset = current_line_count + display_section.highlight_line_offset
  typing_display.apply_highlights(self.buffer, display_section.highlights, total_offset)
end

function SymbolTraining:calculate_xp()
  local base_xp = 100  -- Base XP for completing the full symbol sequence

  local accuracy = session.calculate_accuracy(self.session)

  return xp_module.calculate(base_xp, {
    accuracy = accuracy,
    streak = self.session.current_streak,
  })
end

return SymbolTraining
