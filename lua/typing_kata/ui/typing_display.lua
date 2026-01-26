-- Monkeytype-style typing display component
-- Provides a scrolling "conveyor belt" view with cursor always in middle
local M = {}

-- Configuration
local DISPLAY_WIDTH = 80  -- Width of the typing display area
local CURSOR_POSITION = 40  -- Cursor stays at this column (middle of display)

-- Render the typing display with monkeytype-style scrolling
-- Parameters:
--   target_text: The full text to type
--   current_idx: Current character index (0-based)
--   errors: Table mapping character indices to true if error
--   opts: table { show_sandwich_cursor = bool, cursor_char = string }
function M.render_typing_line(target_text, current_idx, errors, opts)
  opts = opts or {}
  local lines, highlights = {}, {}
  if not target_text then return lines, highlights end

  local display_line = ""
  local active_char_idx = current_idx + 1
  
  for visual_col = 1, DISPLAY_WIDTH do
    local text_idx = active_char_idx + visual_col - CURSOR_POSITION
    local char, hl = ' ', nil
    if text_idx >= 1 and text_idx <= #target_text then
      char = target_text:sub(text_idx, text_idx)
      hl = text_idx < active_char_idx and (errors[text_idx] and 'TypingKataError' or 'TypingKataCorrect') or 'TypingKataUntyped'
    end
    display_line = display_line .. char
    if hl then 
      table.insert(highlights, {
        line = (opts.show_sandwich_cursor and 2 or 1), 
        col_start = visual_col - 1, 
        col_end = visual_col, 
        hl_group = hl
      }) 
    end
  end

  if opts.show_sandwich_cursor then
    table.insert(lines, string.rep(' ', CURSOR_POSITION - 1) .. '▼')
    table.insert(highlights, {line = 1, col_start = CURSOR_POSITION - 1, col_end = CURSOR_POSITION, hl_group = 'TypingKataAccent'})
    table.insert(lines, display_line)
    table.insert(lines, string.rep(' ', CURSOR_POSITION - 1) .. '▲')
    table.insert(highlights, {line = 3, col_start = CURSOR_POSITION - 1, col_end = CURSOR_POSITION, hl_group = 'TypingKataAccent'})
  else
    table.insert(lines, display_line)
    if opts.cursor_char then
      -- Overlay cursor char logic? Or just highlight column.
      table.insert(highlights, {line = 1, col_start = CURSOR_POSITION - 1, col_end = CURSOR_POSITION, hl_group = 'CursorLine'})
    end
  end

  return lines, highlights
end

-- Render a multi-line "Typewriter" view for code
function M.render_typing_page(target_text, current_idx, errors, viewport_height)
  viewport_height = viewport_height or 9
  local lines, highlights = {}, {}
  if not target_text then return lines, highlights end
  
  local code_lines = vim.split(target_text, '\n', { plain = true })
  local line_starts = {}
  local cur_idx = 0
  for _, l in ipairs(code_lines) do
    table.insert(line_starts, cur_idx)
    cur_idx = cur_idx + #l + 1
  end
  
  local active_l, active_c = 1, 0
  local next_g = current_idx + 1
  for i, start in ipairs(line_starts) do
    local end_p = start + #code_lines[i]
    if next_g >= start + 1 and next_g <= end_p then
      active_l, active_c = i, next_g - start - 1
      break
    elseif next_g == end_p + 1 then
      active_l, active_c = i, #code_lines[i]
      break
    end
  end
  if current_idx == 0 then active_l, active_c = 1, 0 end
  
  local half = math.floor(viewport_height / 2)
  local h_shift = CURSOR_POSITION - (active_c + 1)
  
  for i = active_l - half, active_l + half do
    local disp = ""
    local l_num = #lines + 1
    if i >= 1 and i <= #code_lines then
      local content = code_lines[i]
      local g_start = line_starts[i]
      for v_col = 1, DISPLAY_WIDTH do
        local c_idx = v_col - h_shift
        local char, hl = ' ', nil
        if c_idx >= 1 and c_idx <= #content then
          char = content:sub(c_idx, c_idx)
          local pos = g_start + c_idx
          hl = pos <= current_idx and (errors[pos] and 'TypingKataError' or 'TypingKataCorrect') or 'TypingKataUntyped'
        elseif c_idx == #content + 1 and i == active_l and active_c == #content and v_col == CURSOR_POSITION then
          char, hl = '↵', 'TypingKataTarget'
        end
        disp = disp .. char
        if hl then table.insert(highlights, {line = l_num, col_start = v_col - 1, col_end = v_col, hl_group = hl}) end
      end
      -- Draw pipe cursor for active line (Fixed column)
      if i == active_l then
         table.insert(highlights, {line = l_num, col_start = CURSOR_POSITION - 1, col_end = CURSOR_POSITION, hl_group = 'TypingKataCursor'})
      end
    else
      disp = string.rep(' ', DISPLAY_WIDTH)
    end
    table.insert(lines, disp)
  end
  return lines, highlights
end

-- Apply highlights to a buffer
function M.apply_highlights(buffer, highlights, line_offset)
  if not buffer or not vim.api.nvim_buf_is_valid(buffer) then return end
  local ns_id = vim.api.nvim_create_namespace('typing_kata_display')
  vim.api.nvim_buf_clear_namespace(buffer, ns_id, 0, -1)
  for _, hl in ipairs(highlights) do
    local line = (hl.line - 1) + line_offset
    pcall(vim.api.nvim_buf_add_highlight, buffer, ns_id, hl.hl_group, line, hl.col_start, hl.col_end)
  end
end

-- Render a section for 1D carousel
function M.render_section(target_text, current_idx, errors, title, opts)
  local section_lines, all_highlights = {}, {}
  if title then table.insert(section_lines, ''); table.insert(section_lines, '     ' .. title); table.insert(section_lines, '') end
  local disp_lines, hls = M.render_typing_line(target_text, current_idx, errors, opts)
  local h_offset = #section_lines
  for _, line in ipairs(disp_lines) do table.insert(section_lines, '     ' .. line) end
  table.insert(section_lines, '')
  for _, hl in ipairs(hls) do
    table.insert(all_highlights, {line = hl.line, col_start = hl.col_start + 5, col_end = hl.col_end + 5, hl_group = hl.hl_group})
  end
  return { lines = section_lines, highlights = all_highlights, highlight_line_offset = h_offset }
end

return M
