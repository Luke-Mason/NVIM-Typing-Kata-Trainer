-- Submenu UI for showing selections
local M = {}

local buffer_utils = require('typing_kata.ui.buffer')
local config = require('typing_kata.config')

local WIDTH = 50

-- Helper to center text
local function center(text, width)
  local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
  return string.rep(' ', padding) .. text
end

-- Show submenu
-- options: array of {key = 'x', name = 'Option Name', action = function()}
function M.show(title, options, player)
  local buf = buffer_utils.create_scratch_buffer('Submenu: ' .. title)
  M.render(buf, title, options)

  local ui_config = config.current.ui
  local height = #options + 8  -- Dynamic height based on options
  local win = buffer_utils.create_floating_window(buf, {
    width = WIDTH + 4,
    height = height,
    position = ui_config.menu_position,
    border = 'rounded',
    title = ' ' .. title .. ' ',
  })

  if not win then
    vim.notify('Failed to create submenu window', vim.log.levels.ERROR)
    return
  end

  M.setup_keymaps(buf, win, options, player)
end

-- Render submenu content
function M.render(buf, title, options)
  local lines = {}

  table.insert(lines, '')
  table.insert(lines, center(title, WIDTH))
  table.insert(lines, '')
  table.insert(lines, '╭' .. string.rep('─', WIDTH - 2) .. '╮')

  for _, option in ipairs(options) do
    local entry = string.format('│  [%s] %-42s │', option.key, option.name)
    table.insert(lines, entry)
  end

  table.insert(lines, '╰' .. string.rep('─', WIDTH - 2) .. '╯')
  table.insert(lines, '')
  table.insert(lines, center('[q] Back to Main Menu', WIDTH))
  table.insert(lines, '')

  buffer_utils.set_content(buf, lines)
end

-- Setup submenu keymaps
function M.setup_keymaps(buf, win, options, player)
  local opts_keymap = { buffer = buf, noremap = true, silent = true }

  -- Create keymaps for each option
  for _, option in ipairs(options) do
    vim.keymap.set('n', option.key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      option.action()
    end, opts_keymap)
  end

  -- Back to main menu
  local function back()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    require('typing_kata.ui.menu').show(player)
  end

  vim.keymap.set('n', 'q', back, opts_keymap)
  vim.keymap.set('n', '<Esc>', back, opts_keymap)
end

return M
