-- Default configuration for typing-kata plugin
local M = {}

M.defaults = {
  -- Data directory for saves
  data_dir = vim.fn.stdpath('data') .. '/typing_kata',

  -- Keybindings
  keymaps = {
    open_menu = '<leader>tk',  -- Open typing trainer
    exit_mode = '<Esc>',       -- Exit any game mode
  },

  -- UI settings
  ui = {
    menu_position = 'center',  -- 'center', 'top', 'bottom'
    menu_size = { width = 70, height = 25 },
    border = 'rounded',        -- 'none', 'single', 'double', 'rounded'
  },

  -- Statusline integration
  statusline = {
    enabled = true,
    show_rank = true,
    show_xp = true,
  },

  -- Debug mode
  debug = false,
}

-- Current configuration (merged with user config)
M.current = vim.deepcopy(M.defaults)

return M
