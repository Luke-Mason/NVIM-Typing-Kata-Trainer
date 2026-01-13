-- Custom Keybindings Mode: Practice user's actual keybindings
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')

local CustomKeybindings = setmetatable({}, { __index = BaseMode })

function CustomKeybindings:new(player)
  local obj = BaseMode:new(player, 'custom_keybindings')
  setmetatable(obj, { __index = self })
  return obj
end

function CustomKeybindings:setup()
  -- TODO: Parse user's init.lua/vimrc for keybindings
end

function CustomKeybindings:update(key)
  return false
end

function CustomKeybindings:generate_task()
  -- TODO: Generate keybinding practice task
end

function CustomKeybindings:render()
  local lines = {
    '',
    '     🎯 CUSTOM KEYBINDINGS',
    '     =====================',
    '',
    '     This mode is not yet implemented.',
    '     It will parse your init.lua/vimrc and create',
    '     practice tasks for your actual keybindings.',
    '',
    '     Press ESC to return to menu',
    '',
  }
  buffer_utils.set_content(self.buffer, lines)
end

function CustomKeybindings:calculate_xp()
  return 0
end

return CustomKeybindings
