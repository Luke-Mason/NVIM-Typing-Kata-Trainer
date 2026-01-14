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
  vim.api.nvim_buf_set_option(buf, 'wrap', false)
  vim.api.nvim_buf_set_option(buf, 'cursorline', false)
  vim.api.nvim_buf_set_option(buf, 'number', false)
  vim.api.nvim_buf_set_option(buf, 'relativenumber', false)

  if name then
    local existing = vim.fn.bufnr('^' .. name .. '$')
    if existing ~= -1 then
      vim.api.nvim_buf_delete(existing, { force = true })
    end
    pcall(vim.api.nvim_buf_set_name, buf, name)
  end

  return buf
end

-- Set buffer content with automatic highlighting
function M.set_content(buf, lines)
  local was_modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')
  
  if not was_modifiable then
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  if not was_modifiable then
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

  highlights.apply_highlights(buf, lines)
end

-- Create floating window
function M.create_floating_window(buf, opts)
  opts = opts or {}

  local width = opts.width or 70
  local height = opts.height or 25

  local ui = vim.api.nvim_list_uis()[1]
  if not ui then return nil end

  local win_width = ui.width
  local win_height = ui.height

  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

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
  
  -- Aesthetic window options
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:NormalFloat,FloatBorder:TypingKataBorder')
  
  return win
end

function M.open_in_current_window(buf)
  vim.api.nvim_set_current_buf(buf)
end

return M
