-- Symbol Training Mode: Practice special characters and symbols
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')

local SymbolTraining = setmetatable({}, { __index = BaseMode })

-- Symbol categories
SymbolTraining.SYMBOLS = {
  -- Single characters
  '(', ')', '[', ']', '{', '}', '<', '>',
  '+', '-', '*', '/', '=', '!', '?', '.',
  ',', ';', ':', "'", '"', '`', '~', '@',
  '#', '$', '%', '^', '&', '|', '\\',

  -- Common combinations
  '==', '!=', '<=', '>=', '->', '=>', '::',
  '&&', '||', '++', '--', '+=', '-=', '*=', '/=',
  '/*', '*/', '//', '<!--', '-->', '<?', '?>',
}

function SymbolTraining:new(player)
  local obj = BaseMode:new(player, 'symbol_training')
  setmetatable(obj, { __index = self })

  obj.symbols_per_session = 50
  obj.current_symbol_idx = 1
  obj.symbol_list = {}
  obj.current_symbol = ''
  obj.typed_text = ''
  obj.waiting_for_input = false

  return obj
end

function SymbolTraining:setup()
  -- Generate random symbol list
  for i = 1, self.symbols_per_session do
    local symbol = self.SYMBOLS[math.random(#self.SYMBOLS)]
    table.insert(self.symbol_list, symbol)
  end
end

function SymbolTraining:generate_task()
  if self.current_symbol_idx > #self.symbol_list then
    -- Session complete
    self:exit()
    return
  end

  self.current_symbol = self.symbol_list[self.current_symbol_idx]
  self.typed_text = ''
  self.waiting_for_input = true
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

  -- Enter to submit
  vim.keymap.set('i', '<CR>', function() return self:submit() end, opts)
end

function SymbolTraining:handle_char(char)
  if not self.waiting_for_input then
    return ''
  end

  local expected_char = self.current_symbol:sub(#self.typed_text + 1, #self.typed_text + 1)

  if char == expected_char then
    self.typed_text = self.typed_text .. char
    session.record_keystroke(self.session, true)

    -- Check if symbol is complete
    if self.typed_text == self.current_symbol then
      self:complete_symbol()
    end
  else
    session.record_keystroke(self.session, false)
    session.break_streak(self.session)
  end

  self:render()
  return ''  -- Don't actually insert the character
end

function SymbolTraining:backspace()
  if #self.typed_text > 0 then
    self.typed_text = self.typed_text:sub(1, -2)
    self:render()
  end
  return ''
end

function SymbolTraining:submit()
  if self.typed_text == self.current_symbol then
    self:complete_symbol()
  end
  return ''
end

function SymbolTraining:complete_symbol()
  local xp = self:calculate_xp()
  session.add_task_completion(self.session, xp)
  session.increment_streak(self.session)

  self.current_symbol_idx = self.current_symbol_idx + 1
  self:generate_task()
  self:render()
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
  local progress_text = string.format('     Progress: %d/%d', self.current_symbol_idx - 1, self.symbols_per_session)
  table.insert(lines, progress_text)
  table.insert(lines, '')

  -- Current symbol to type
  table.insert(lines, '     Type this symbol:')
  table.insert(lines, '')
  table.insert(lines, '          ' .. self.current_symbol)
  table.insert(lines, '')
  table.insert(lines, '')

  -- User typing
  table.insert(lines, '     You typed: ' .. self.typed_text)
  table.insert(lines, '')
  table.insert(lines, '')

  -- Stats
  local accuracy = session.calculate_accuracy(self.session)
  table.insert(lines, string.format('     Accuracy: %.1f%%', accuracy))
  table.insert(lines, string.format('     Streak: %d', self.session.current_streak))
  table.insert(lines, string.format('     XP Earned: %d', self.session.xp_earned))
  table.insert(lines, '')

  -- Add consistent controls legend
  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type the symbol exactly as shown'},
    {key = 'ENTER', desc = 'Submit symbol'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
end

function SymbolTraining:calculate_xp()
  local base_xp = 5

  -- Simple XP for symbols (single character = 5, combo = 10)
  if #self.current_symbol > 1 then
    base_xp = 10
  end

  local accuracy = session.calculate_accuracy(self.session)

  return xp_module.calculate(base_xp, {
    accuracy = accuracy,
    streak = self.session.current_streak,
  })
end

return SymbolTraining
