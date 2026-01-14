-- Vim Motions Mode: Practice typing vim motion key sequences (muscle memory)
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')
local motions_data = require('typing_kata.core.data.vim_motions')
local typing_display = require('typing_kata.ui.typing_display')

local VimMotions = setmetatable({}, { __index = BaseMode })

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
  local all_motions = motions_data.motions
  
  for i = 1, self.motions_per_session do
    local motion = all_motions[math.random(#all_motions)]
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
    
    -- Use Carousel Display
    -- "target_text" is the key sequence (self.current_motion.keys)
    -- "current_idx" is the length of "typed_sequence"? 
    -- Logic check: typed_sequence builds up.
    -- errors? We reset on error, so errors table is effectively empty/unused for visual red?
    -- Actually, if we reset immediately, we never show red.
    -- User wants muscle memory.
    -- Maybe we should SHOW the error briefly? 
    -- Current logic: resets immediately.
    -- Let's stick to current logic for now: visual typing of the target.
    
    local errors = {} -- No persistent errors in this mode yet
    local display_section = typing_display.render_section(
      self.current_motion.keys,
      #self.typed_sequence,
      errors,
      "Type the keys:"
    )
    
    local current_line_count = #lines
    for _, line in ipairs(display_section.lines) do
      table.insert(lines, line)
    end
    
    -- We need to apply highlights later
    self.pending_highlights = display_section.highlights
    self.pending_highlight_offset = current_line_count + display_section.highlight_line_offset
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
    {key = 'BACKSPACE', desc = 'Delete last character'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
  
  if self.pending_highlights then
    typing_display.apply_highlights(self.buffer, self.pending_highlights, self.pending_highlight_offset)
    self.pending_highlights = nil
  end
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
