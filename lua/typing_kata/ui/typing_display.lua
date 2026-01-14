-- Monkeytype-style typing display component
-- Provides a scrolling "conveyor belt" view with cursor always in middle
local M = {}

-- Configuration
local DISPLAY_WIDTH = 80  -- Width of the typing display area
local CURSOR_POSITION = 40  -- Cursor stays at this column (middle of display)

-- Render the typing display with monkeytype-style scrolling
-- Parameters:
--   target_text: The full text to type
--   current_idx: Current character index (0-based, number of chars completed)
--   errors: Table mapping character indices to true if error
-- Returns:
--   lines: Array of lines to display
--   highlights: Array of highlight information {line, col_start, col_end, hl_group}
function M.render_typing_line(target_text, current_idx, errors)
  local lines = {}
  local highlights = {}

  if not target_text then
    return lines, highlights
  end

  local display_line = ""
  
  -- We want the NEXT character (current_idx + 1) to be at CURSOR_POSITION
  local active_char_idx = current_idx + 1
  
  -- Iterate through visual columns of the display
  local line_num = 1 -- We only generate one line of text here (+ cursor line)
  
  for visual_col = 1, DISPLAY_WIDTH do
    -- Calculate which character from target_text belongs at this visual column
    -- Formula: text_idx - active_char_idx = visual_col - CURSOR_POSITION
    local text_idx = active_char_idx + visual_col - CURSOR_POSITION
    
    local char_to_display = ' ' -- Default to empty space (padding)
    local hl_group = nil
    
    if text_idx >= 1 and text_idx <= #target_text then
      local char = target_text:sub(text_idx, text_idx)
      
      -- Replace spaces with visible character if needed, or keep as space
      -- For coding modes, space is space.
      char_to_display = char
      
      -- Determine Highlight
      if text_idx < active_char_idx then
        -- Already typed (Past)
        if errors[text_idx] then
          hl_group = 'TypingKataError'
        else
          hl_group = 'TypingKataCorrect'
        end
      elseif text_idx == active_char_idx then
        -- Current character (Under Cursor)
        -- Usually we highlight the cursor position specially, or leave it as Untyped/Target
        -- If user typed wrong previously on this index (and backspaced?), checking errors[text_idx] might be valid?
        -- Usually errors are cleared on backspace.
        hl_group = 'TypingKataTarget' -- Use distinct color for current target? Or Untyped.
        -- Let's stick to Untyped for now to match "grey" expectation, or Target (White).
        -- User said: "symbols to the right ... were not greyed out".
        -- User said: "When i get a character correct, only then is it meant to turn from grey to white".
        -- So Untyped = Grey. Correct = White/Green.
        hl_group = 'TypingKataUntyped'
        
        -- If we want to highlight the cursor specifically (e.g. underline), we can do that too.
        -- But we draw a caret ▼ below.
      else
        -- Future character
        hl_group = 'TypingKataUntyped'
      end
    end
    
    display_line = display_line .. char_to_display
    
    if hl_group then
      table.insert(highlights, {
        line = line_num,
        col_start = visual_col - 1, -- 0-based column
        col_end = visual_col,
        hl_group = hl_group
      })
    end
  end

  -- Add cursor indicator line (TOP)
  local cursor_line_top = string.rep(' ', CURSOR_POSITION - 1) .. '▼'
  table.insert(lines, cursor_line_top)

  -- Add the text line
  table.insert(lines, display_line)

  -- Add cursor indicator line (BOTTOM)
  local cursor_line_bottom = string.rep(' ', CURSOR_POSITION - 1) .. '▲'
  table.insert(lines, cursor_line_bottom)
  
  -- Highlights for cursors
  -- Top Cursor (Line 1)
  table.insert(highlights, {
    line = 1,
    col_start = CURSOR_POSITION - 1,
    col_end = CURSOR_POSITION,
    hl_group = 'TypingKataAccent'
  })
  
  -- Text highlights need to be shifted down by 1 line now (Line 2)
  for _, hl in ipairs(highlights) do
    if hl.line == 1 and hl.hl_group ~= 'TypingKataAccent' then
       hl.line = 2
    end
  end
  
  -- Bottom Cursor (Line 3)
  table.insert(highlights, {
    line = 3,
    col_start = CURSOR_POSITION - 1,
    col_end = CURSOR_POSITION,
    hl_group = 'TypingKataAccent'
  })

  return lines, highlights
end

-- Render a multi-line "Typewriter" view for code
-- Parameters:
--   target_text: Full code string (with newlines)
--   current_idx: Global index of current char
--   errors: Error table
--   viewport_height: Number of context lines (odd number recommended, e.g., 5, 7)
function M.render_typing_page(target_text, current_idx, errors, viewport_height)
  viewport_height = viewport_height or 5
  local lines = {}
  local highlights = {}
  
  if not target_text then return lines, highlights end
  
  -- 1. Analyze text structure (split into lines and map global indices)
  local code_lines = vim.split(target_text, '\n', { plain = true })
  local line_start_indices = {} -- Global index where each line starts
  local current_global_idx = 0
  
  for i, line_content in ipairs(code_lines) do
    table.insert(line_start_indices, current_global_idx)
    current_global_idx = current_global_idx + #line_content + 1 -- +1 for newline
  end
  
  -- 2. Find active line and col
  local active_line_idx = 1
  local active_col_idx = 0 -- 0-based index in the current line
  
  -- We need to find which line contains current_idx (next char to type)
  -- If current_idx == length, we are at the end.
  local next_char_global_idx = current_idx + 1
  
  for i = 1, #code_lines do
    local start = line_start_indices[i]
    local len = #code_lines[i]
    local end_pos = start + len -- Position of the newline character
    
    if next_char_global_idx > start and next_char_global_idx <= end_pos then
      active_line_idx = i
      active_col_idx = next_char_global_idx - start - 1
      break
    elseif next_char_global_idx == end_pos + 1 then
      -- We are ON the newline character (waiting to press Enter)
      active_line_idx = i
      active_col_idx = len -- Position after last char
      break
    end
  end
  
  -- Edge case: Start of file
  if current_idx == 0 then
    active_line_idx = 1
    active_col_idx = 0
  end
  
  -- 3. Determine Viewport (Vertical Window)
  -- Center active_line_idx
  local half_height = math.floor(viewport_height / 2)
  local start_line = active_line_idx - half_height
  local end_line = active_line_idx + half_height
  
  -- 4. Calculate Horizontal Offset
  -- We want active_col_idx to be at CURSOR_POSITION
  -- So we shift ALL lines by: offset = CURSOR_POSITION - active_col_idx
  -- Wait, active_col_idx is 0-based. 
  -- If active_col_idx is 0 (first char), we want it at CURSOR_POSITION.
  -- visual_col = text_col + offset
  -- CURSOR_POSITION = 1 + offset => offset = CURSOR_POSITION - 1
  -- formula: visual_pos = (char_idx_in_line + 1) + (CURSOR_POSITION - (active_col_idx + 1))
  -- visual_pos = char_idx_in_line + CURSOR_POSITION - active_col_idx
  
  local horizontal_shift = CURSOR_POSITION - (active_col_idx + 1)
  
  -- 5. Render Lines
  for i = start_line, end_line do
    local display_line_str = ""
    local line_num_in_buffer = #lines + 1
    
    if i >= 1 and i <= #code_lines then
      local content = code_lines[i]
      local global_start = line_start_indices[i]
      
      -- Iterate visual columns
      for vis_col = 1, DISPLAY_WIDTH do
        -- Calculate text index for this visual column
        -- vis_col = char_idx + horizontal_shift
        -- char_idx = vis_col - horizontal_shift
        local char_idx = vis_col - horizontal_shift -- 1-based index in line
        
        local char = ' '
        local hl_group = nil
        
        if char_idx >= 1 and char_idx <= #content then
          char = content:sub(char_idx, char_idx)
          local char_global_pos = global_start + char_idx
          
          -- Highlights
          if char_global_pos <= current_idx then
             if errors[char_global_pos] then
               hl_group = 'TypingKataError'
             else
               hl_group = 'TypingKataCorrect'
             end
          elseif char_global_pos == current_idx + 1 then
             -- This is the cursor position if on a char
             hl_group = 'TypingKataUntyped' 
          else
             hl_group = 'TypingKataUntyped'
          end
        elseif char_idx == #content + 1 then
           -- Newline position
           -- If this is the active line and we are at the end, this is the cursor pos
           if i == active_line_idx and active_col_idx == #content then
              -- Cursor is here (waiting for Enter)
              -- We can show a symbol like ↵
              if vis_col == CURSOR_POSITION then
                 char = '↵'
                 hl_group = 'TypingKataTarget'
              end
           end
           
           -- If we typed past it (hit enter), check error?
           -- Newlines are handled as logic, but visual representation is tricky.
           local nl_global_pos = global_start + #content + 1
           if nl_global_pos <= current_idx and errors[nl_global_pos] then
              -- Missed newline?
              if vis_col == (char_idx + horizontal_shift) then -- Logic check
                 char = '↵'
                 hl_group = 'TypingKataError'
              end
           end
        end
        
        display_line_str = display_line_str .. char
        
        if hl_group then
          table.insert(highlights, {
            line = line_num_in_buffer,
            col_start = vis_col - 1,
            col_end = vis_col,
            hl_group = hl_group
          })
        end
      end
    else
      -- Out of bounds line (empty space)
      display_line_str = string.rep(' ', DISPLAY_WIDTH)
    end
    
    table.insert(lines, display_line_str)
  end
  
  -- Add cursors (Sandwich) ONLY on the middle line (which is the active line)
  -- The active line is at index: half_height + 1
  -- We need to insert the sandwich arrows into the `lines` array?
  -- No, the user wants "vertical carousel". The text moves up/down.
  -- The cursor is fixed at screen center.
  -- So we draw separate cursor lines overlaying? 
  -- Or we just inject the cursor markers into the lines array above/below the active line?
  -- Wait, if `viewport_height` is 5.
  -- Lines: 1, 2, 3(Active), 4, 5.
  -- We want cursors around line 3.
  -- We can't easily "inject" lines without messing up the code spacing if we want compact code.
  -- But "Sandwich" implies lines above and below.
  -- Let's replace the content of line 2 and 4 with cursors? No, that hides code.
  -- 
  -- Solution: We render the cursor *markers* using Extmarks (virtual text) or just highlights?
  -- Or we accept that for Coding Mode, the "Sandwich" might overlap with text lines?
  -- 
  -- Actually, let's keep it simple:
  -- Render a distinct "Cursor Line" or "Ruler" at the center line index?
  -- Or just highlighting the character background (which we do with 'TypingKataTarget').
  -- 
  -- User Request: "carousel... extra feature... vertical carousel... page moves around cursor".
  -- User Request earlier: "triangle above and below".
  -- 
  -- If I add a triangle line *between* code lines, it doubles the vertical space.
  -- Code:
  --   line 1
  --   line 2
  --      ▼
  --   line 3 (active)
  --      ▲
  --   line 4
  -- 
  -- This is fine for a typing trainer! It focuses on the active line.
  -- So yes, `render_typing_page` should probably render:
  --   Line i
  --   Line i+1
  --   CURSOR TOP
  --   Active Line
  --   CURSOR BOTTOM
  --   Line i+2
  -- 
  -- Modified Algorithm Step 5:
  -- Iterate lines.
  -- If i == active_line_idx:
  --    Insert Cursor Top Line
  --    Insert Code Line
  --    Insert Cursor Bottom Line
  -- Else:
  --    Insert Code Line
  
  local final_lines = {}
  local final_highlights = {}
  local hl_offset_map = {} -- Map logical lines to buffer lines to fix highlights
  
  for i = start_line, end_line do
    -- Generate the code line string/highlights (logic from above)
    -- ... (Copying logic) ...
    local line_content_str = ""
    local line_hls = {}
    
    -- (Logic repeated for clarity, implementation will combine)
    if i >= 1 and i <= #code_lines then
       -- ... calculate line_content_str ...
       local content = code_lines[i]
       local global_start = line_start_indices[i]
       
       for vis_col = 1, DISPLAY_WIDTH do
          local char_idx = vis_col - horizontal_shift
          local char = ' '
          local hl = nil
          
          if char_idx >= 1 and char_idx <= #content then
             char = content:sub(char_idx, char_idx)
             local g_pos = global_start + char_idx
             if g_pos <= current_idx then
                if errors[g_pos] then hl = 'TypingKataError' else hl = 'TypingKataCorrect' end
             else
                hl = 'TypingKataUntyped'
             end
          elseif char_idx == #content + 1 then
             -- Newline char logic
             if i == active_line_idx and active_col_idx == #content and vis_col == CURSOR_POSITION then
                char = '↵'
                hl = 'TypingKataTarget'
             end
          end
          
          line_content_str = line_content_str .. char
          if hl then table.insert(line_hls, {c_s=vis_col-1, c_e=vis_col, hl=hl}) end
       end
    else
       line_content_str = string.rep(' ', DISPLAY_WIDTH)
    end
    
    -- Insert into buffer lines
    if i == active_line_idx then
       table.insert(final_lines, string.rep(' ', CURSOR_POSITION - 1) .. '▼')
       table.insert(final_highlights, {line=#final_lines, col_start=CURSOR_POSITION-1, col_end=CURSOR_POSITION, hl_group='TypingKataAccent'})
       
       table.insert(final_lines, line_content_str)
       local active_buf_line = #final_lines
       for _, h in ipairs(line_hls) do
          table.insert(final_highlights, {line=active_buf_line, col_start=h.c_s, col_end=h.c_e, hl_group=h.hl})
       end
       
       table.insert(final_lines, string.rep(' ', CURSOR_POSITION - 1) .. '▲')
       table.insert(final_highlights, {line=#final_lines, col_start=CURSOR_POSITION-1, col_end=CURSOR_POSITION, hl_group='TypingKataAccent'})
    else
       table.insert(final_lines, line_content_str)
       local buf_line = #final_lines
       for _, h in ipairs(line_hls) do
          table.insert(final_highlights, {line=buf_line, col_start=h.c_s, col_end=h.c_e, hl_group=h.hl})
       end
    end
  end
  
  return final_lines, final_highlights
end

-- Apply highlights to a buffer
-- Parameters:
--   buffer: Buffer handle
--   highlights: Array of {line, col_start, col_end, hl_group}
--   line_offset: Offset to add to line numbers (for positioning in buffer)
function M.apply_highlights(buffer, highlights, line_offset)
  if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
    return
  end

  local ns_id = vim.api.nvim_create_namespace('typing_kata_display')
  
  -- Clear existing highlights in this namespace
  vim.api.nvim_buf_clear_namespace(buffer, ns_id, 0, -1)
  vim.api.nvim_buf_clear_namespace(buffer, ns_id, 0, -1)

  -- Apply new highlights
  for _, hl in ipairs(highlights) do
    local line = (hl.line - 1) + line_offset  -- Convert to 0-based and add offset
    local ok, err = pcall(vim.api.nvim_buf_add_highlight,
      buffer,
      ns_id,
      hl.hl_group,
      line,
      hl.col_start,
      hl.col_end
    )
    if not ok then
      vim.notify("Highlight Error: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

-- Render a complete typing display section for insertion into mode buffers
-- Returns a table with:
--   lines: Array of lines to insert
--   highlights: Array of highlight information
--   highlight_line_offset: Offset where highlights should be applied
function M.render_section(target_text, current_idx, errors, title)
  local section_lines = {}
  local all_highlights = {}

  -- Title
  if title then
    table.insert(section_lines, '')
    table.insert(section_lines, '     ' .. title)
    table.insert(section_lines, '')
  end

  -- Typing area
  local display_lines, highlights = M.render_typing_line(target_text, current_idx, errors)

  -- Track where highlights should start
  local highlight_offset = #section_lines

  -- Center the display
  for _, line in ipairs(display_lines) do
    table.insert(section_lines, '     ' .. line)
  end

  table.insert(section_lines, '')

  -- Adjust highlight columns for the "     " prefix
  for _, hl in ipairs(highlights) do
    table.insert(all_highlights, {
      line = hl.line,
      col_start = hl.col_start + 5,  -- Account for "     " prefix
      col_end = hl.col_end + 5,
      hl_group = hl.hl_group
    })
  end

  return {
    lines = section_lines,
    highlights = all_highlights,
    highlight_line_offset = highlight_offset
  }
end

return M
