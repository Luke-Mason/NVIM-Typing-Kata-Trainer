-- Test initialization file for typing-kata plugin
-- Run with: nvim -u test_init.lua

-- Add current directory to runtimepath so Neovim can find our plugin
vim.opt.runtimepath:prepend('.')

-- Setup the plugin
require('typing_kata').setup({
  keymaps = {
    open_menu = '<leader>tk',
  },
  ui = {
    menu_size = { width = 70, height = 25 },
    border = 'rounded',
  },
})

-- Create a keymap to open the trainer
vim.keymap.set('n', '<leader>tk', ':TypingKata<CR>', { desc = 'Open Typing Trainer' })

-- Print success message
vim.notify('Typing Kata Plugin Loaded! Press <leader>tk to start', vim.log.levels.INFO)

-- Automatically open the trainer after 1 second
vim.defer_fn(function()
  vim.cmd('TypingKata')
end, 1000)
