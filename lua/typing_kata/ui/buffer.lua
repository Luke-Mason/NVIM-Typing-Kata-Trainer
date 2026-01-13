-- Buffer rendering utilities
local M = {}
local highlights = require('typing_kata.ui.highlights')

-- Create a scratch buffer for game mode
function M.create_scratch_buffer(name)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'wrap', false)  -- Disable line wrapping
  vim.api.nvim_buf_set_option(buf, 'cursorline', false)
  vim.api.nvim_buf_set_option(buf, 'number', false)
  vim.api.nvim_buf_set_option(buf, 'relativenumber', false)

  if name then
    vim.api.nvim_buf_set_name(buf, name)
  end

  return buf
end

-- Set buffer content with automatic highlighting
function M.set_content(buf, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Apply automatic highlighting
  highlights.apply_highlights(buf, lines)
end

-- Create floating window
function M.create_floating_window(buf, opts)
  opts = opts or {}

  local width = opts.width or 70
  local height = opts.height or 25

  -- Get editor dimensions
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return nil
  end

  local win_width = ui.width
  local win_height = ui.height

  -- Center the window
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  -- Override if position specified
  if opts.position == 'top' then
    row = 2
  elseif opts.position == 'bottom' then
    row = win_height - height - 2
  end

  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = opts.border or 'rounded',
  }

  if opts.title then
    win_opts.title = opts.title
    win_opts.title_pos = 'center'
  end

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  return win
end

-- Open buffer in current window (full screen)
function M.open_in_current_window(buf)
  vim.api.nvim_set_current_buf(buf)
end

-- Add highlighting to specific lines
function M.add_highlight(buf, hl_group, line, col_start, col_end)
  local ns_id = vim.api.nvim_create_namespace('typing_kata')
  vim.api.nvim_buf_add_highlight(buf, ns_id, hl_group, line, col_start, col_end)
end

-- Clear all highlights in buffer
function M.clear_highlights(buf)
  local ns_id = vim.api.nvim_create_namespace('typing_kata')
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
end

return M
