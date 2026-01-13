-- Base class for all game modes
local buffer_utils = require('typing_kata.ui.buffer')
local session_module = require('typing_kata.core.session')
local player_module = require('typing_kata.core.player')

local BaseMode = {}
BaseMode.__index = BaseMode

function BaseMode:new(player, mode_name)
  local obj = {
    player = player,
    mode_name = mode_name,
    session = nil,
    is_running = false,
    buffer = nil,
    window = nil,
  }
  setmetatable(obj, self)
  return obj
end

-- Abstract methods (must be overridden by subclasses)
function BaseMode:setup()
  error(self.mode_name .. ': setup() must be implemented by subclass')
end

function BaseMode:update(key)
  error(self.mode_name .. ': update(key) must be implemented by subclass')
end

function BaseMode:generate_task()
  error(self.mode_name .. ': generate_task() must be implemented by subclass')
end

function BaseMode:render()
  error(self.mode_name .. ': render() must be implemented by subclass')
end

function BaseMode:calculate_xp()
  error(self.mode_name .. ': calculate_xp() must be implemented by subclass')
end

-- Concrete methods (provided by base class)
function BaseMode:start()
  self.session = session_module.new(self.mode_name)
  self.is_running = true

  self:setup()
  self:generate_task()
  self:create_buffer()
  self:render()
end

function BaseMode:create_buffer()
  -- Create scratch buffer
  self.buffer = buffer_utils.create_scratch_buffer('Typing Kata - ' .. self.mode_name)

  -- Open in current window (full screen)
  buffer_utils.open_in_current_window(self.buffer)

  -- Setup keymaps for this buffer
  self:setup_buffer_keymaps()
end

function BaseMode:setup_buffer_keymaps()
  local opts = { buffer = self.buffer, noremap = true, silent = true }

  -- Exit on ESC
  vim.keymap.set('n', '<Esc>', function() self:exit() end, opts)

  -- Subclasses can override to add more keymaps
end

function BaseMode:handle_input(key)
  local task_complete = self:update(key)

  if task_complete then
    local xp = self:calculate_xp()
    session_module.add_task_completion(self.session, xp)
    self:generate_task()
  end

  self:render()
end

function BaseMode:exit()
  self.is_running = false
  session_module.end_session(self.session)

  -- Update player stats
  player_module.update_from_session(self.player, self.session)

  -- Save player
  player_module.save(self.player)

  -- Show summary
  self:show_summary()

  -- Close buffer
  if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
    vim.api.nvim_buf_delete(self.buffer, { force = true })
  end

  -- Return to menu
  require('typing_kata.ui.menu').show(self.player)
end

function BaseMode:show_summary()
  local summary = session_module.get_summary(self.session)
  vim.notify(summary, vim.log.levels.INFO)
end

-- Generate consistent controls legend for all modes
-- controls: array of {key = "ESC", desc = "Back to menu"} tables
function BaseMode:render_controls_legend(controls)
  local lines = {}

  table.insert(lines, '')
  table.insert(lines, '─────────────────────────────────────── CONTROLS ───────────────────────────────────────')

  for _, control in ipairs(controls) do
    table.insert(lines, string.format('  [%s] %s', control.key, control.desc))
  end

  table.insert(lines, '─────────────────────────────────────────────────────────────────────────────────────────')
  table.insert(lines, '')

  return lines
end

return BaseMode
