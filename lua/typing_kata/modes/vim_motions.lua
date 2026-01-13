-- Vim Motions Mode: Practice typing vim motion key sequences (muscle memory)
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')

local VimMotions = setmetatable({}, { __index = BaseMode })

-- Vim motion sequences with descriptions
VimMotions.MOTIONS = {
  -- Basic motions
  {keys = "h", desc = "Move left"},
  {keys = "j", desc = "Move down"},
  {keys = "k", desc = "Move up"},
  {keys = "l", desc = "Move right"},
  {keys = "w", desc = "Move to start of next word"},
  {keys = "b", desc = "Move to start of previous word"},
  {keys = "e", desc = "Move to end of word"},
  {keys = "0", desc = "Move to start of line"},
  {keys = "$", desc = "Move to end of line"},

  -- Word motions with counts
  {keys = "5w", desc = "Move 5 words forward"},
  {keys = "3b", desc = "Move 3 words back"},
  {keys = "10j", desc = "Move 10 lines down"},
  {keys = "7k", desc = "Move 7 lines up"},

  -- Search motions
  {keys = "f", desc = "Find character forward in line (followed by char)"},
  {keys = "t", desc = "Till character forward (before char)"},
  {keys = "F", desc = "Find character backward in line"},
  {keys = "T", desc = "Till character backward"},

  -- Text objects and operators
  {keys = "d", desc = "Delete operator"},
  {keys = "c", desc = "Change operator"},
  {keys = "y", desc = "Yank (copy) operator"},
  {keys = "v", desc = "Visual mode"},
  {keys = "V", desc = "Visual line mode"},

  -- Combined operations
  {keys = "dw", desc = "Delete word"},
  {keys = "d3w", desc = "Delete 3 words"},
  {keys = "ciw", desc = "Change inner word"},
  {keys = "di(", desc = "Delete inside parentheses"},
  {keys = "yi\"", desc = "Yank inside double quotes"},
  {keys = "va{", desc = "Visual select around braces"},
  {keys = "dt;", desc = "Delete till semicolon"},

  -- Control combinations
  {keys = "<C-d>", desc = "Scroll down half page"},
  {keys = "<C-u>", desc = "Scroll up half page"},
  {keys = "<C-f>", desc = "Scroll down full page"},
  {keys = "<C-b>", desc = "Scroll up full page"},
  {keys = "<C-o>", desc = "Jump to previous location"},
  {keys = "<C-i>", desc = "Jump to next location"},
  {keys = "<C-r>", desc = "Redo"},
  {keys = "<C-w>v", desc = "Split window vertically"},
  {keys = "<C-w>s", desc = "Split window horizontally"},
  {keys = "<C-w>h", desc = "Move to left window"},
  {keys = "<C-w>j", desc = "Move to bottom window"},
  {keys = "<C-w>k", desc = "Move to top window"},
  {keys = "<C-w>l", desc = "Move to right window"},

  -- Insert mode combinations
  {keys = "<C-n>", desc = "Autocomplete next"},
  {keys = "<C-p>", desc = "Autocomplete previous"},
  {keys = "<C-x><C-o>", desc = "Omni completion"},
  {keys = "<C-x><C-f>", desc = "File path completion"},

  -- Command combinations
  {keys = "gg", desc = "Go to first line"},
  {keys = "G", desc = "Go to last line"},
  {keys = "50G", desc = "Go to line 50"},
  {keys = "u", desc = "Undo"},
  {keys = ".", desc = "Repeat last change"},
  {keys = ">>", desc = "Indent line"},
  {keys = "<<", desc = "Unindent line"},
  {keys = "==", desc = "Auto-indent line"},

  -- Marks and jumps
  {keys = "ma", desc = "Set mark 'a'"},
  {keys = "'a", desc = "Jump to mark 'a'"},
  {keys = "``", desc = "Jump to last position"},

  -- Macros
  {keys = "qa", desc = "Record macro to register 'a'"},
  {keys = "q", desc = "Stop recording macro"},
  {keys = "@a", desc = "Play macro from register 'a'"},
  {keys = "@@", desc = "Repeat last macro"},
}

function VimMotions:new(player)
  local obj = BaseMode:new(player, 'vim_motions')
  setmetatable(obj, { __index = self })

  obj.motions_per_session = 20
  obj.current_motion_idx = 1
  obj.motion_list = {}
  obj.current_motion = nil
  obj.typed_sequence = ""

  return obj
end

function VimMotions:setup()
  -- Generate random motion list
  for i = 1, self.motions_per_session do
    local motion = self.MOTIONS[math.random(#self.MOTIONS)]
    table.insert(self.motion_list, motion)
  end
end

function VimMotions:generate_task()
  if self.current_motion_idx > #self.motion_list then
    self:exit()
    return
  end

  self.current_motion = self.motion_list[self.current_motion_idx]
  self.typed_sequence = ""
end

function VimMotions:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function VimMotions:setup_buffer_keymaps()
  BaseMode.setup_buffer_keymaps(self)

  vim.schedule(function()
    if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
      vim.cmd('startinsert')
    end
  end)

  local opts = { buffer = self.buffer, noremap = true, silent = true }

  -- Map all characters
  local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local symbols = '`~!@#$%^&*()-_=+[{]}\\|;:\'"<.>/?'

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

function VimMotions:handle_char(char)
  self.typed_sequence = self.typed_sequence .. char

  -- Check if matches or could match
  local target = self.current_motion.keys

  if self.typed_sequence == target then
    -- Exact match! Move to next
    self:complete_motion()
  elseif #self.typed_sequence >= #target then
    -- Too long and doesn't match - error
    session.record_keystroke(self.session, false)
    session.break_streak(self.session)
    self.typed_sequence = ""  -- Reset
  else
    -- Still building the sequence
    if target:sub(1, #self.typed_sequence) == self.typed_sequence then
      -- On the right track
      session.record_keystroke(self.session, true)
    else
      -- Wrong sequence
      session.record_keystroke(self.session, false)
      session.break_streak(self.session)
      self.typed_sequence = ""  -- Reset
    end
  end

  self:render()
  return ''
end

function VimMotions:backspace()
  if #self.typed_sequence > 0 then
    self.typed_sequence = self.typed_sequence:sub(1, -2)
    self:render()
  end
  return ''
end

function VimMotions:submit()
  if self.typed_sequence == self.current_motion.keys then
    self:complete_motion()
  end
  return ''
end

function VimMotions:complete_motion()
  local xp = self:calculate_xp()
  session.add_task_completion(self.session, xp)
  session.increment_streak(self.session)

  self.current_motion_idx = self.current_motion_idx + 1
  self:generate_task()
  self:render()
end

function VimMotions:update(key)
  return false
end

function VimMotions:render()
  local lines = {}

  -- Title
  table.insert(lines, '')
  table.insert(lines, '          ⚡ VIM MOTIONS - KEY SEQUENCE PRACTICE')
  table.insert(lines, '          ========================================')
  table.insert(lines, '')

  -- Progress
  table.insert(lines, string.format('     Motion: %d/%d',
    self.current_motion_idx, self.motions_per_session))
  table.insert(lines, '')

  -- Current motion description
  if self.current_motion then
    table.insert(lines, '     Description:')
    table.insert(lines, '     ' .. self.current_motion.desc)
    table.insert(lines, '')
    table.insert(lines, '     Type the vim motion keys:')
    table.insert(lines, '')
    table.insert(lines, '          Target: ' .. self.current_motion.keys)
    table.insert(lines, '          You typed: ' .. self.typed_sequence)
    table.insert(lines, '')
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
    {key = 'Type', desc = 'Enter the key sequence (press actual keys: Ctrl+u = <C-u>)'},
    {key = 'ENTER', desc = 'Submit sequence'},
    {key = 'BACKSPACE', desc = 'Delete last character'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
end

function VimMotions:calculate_xp()
  local base_xp = 15

  local accuracy = session.calculate_accuracy(self.session)

  return xp_module.calculate(base_xp, {
    accuracy = accuracy,
    streak = self.session.current_streak,
  })
end

return VimMotions
