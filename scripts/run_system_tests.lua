local M = {}

-- Utility to log results
local log_file = nil
function M.log(msg)
  if log_file then log_file:write(msg .. "\n") end
  print(msg)
end

function M.setup()
  log_file = io.open("system_test.log", "w")
  M.log("🚀 Starting System Test Suite...")
  
  -- Setup Neovim environment
  vim.opt.swapfile = false
  package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'
  
  -- Deterministic RNG
  math.randomseed(12345)
  
  -- Load Plugin
  require('typing_kata').setup({
    data_dir = "./tests/temp_data"
  })
end

function M.teardown()
  if log_file then log_file:close() end
  vim.cmd('qall!')
end

-- Helper: Assert buffer is valid and modifiable if required
function M.assert_buffer_ready(mode, requires_modifiable)
  local buf = mode.buffer
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    error("❌ Buffer not created for " .. mode.mode_name)
  end
  
  local modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')
  if requires_modifiable and not modifiable then
    error("❌ Buffer not modifiable for " .. mode.mode_name)
  end
  
  M.log("  ✓ " .. mode.mode_name .. " buffer ready (modifiable=" .. tostring(modifiable) .. ")")
  return buf
end

-- Helper: Check for specific highlight group at position
function M.assert_highlight(buf, line, col, expected_group)
  local ns_id = vim.api.nvim_create_namespace('typing_kata_display')
  -- Get extmarks at specific line
  local extmarks = vim.api.nvim_buf_get_extmarks(buf, ns_id, {line, 0}, {line, -1}, {details = true})
  
  local found = false
  for _, mark in ipairs(extmarks) do
    local mark_col = mark[3]
    local details = mark[4]
    local end_col = details.end_col
    local hl_group = details.hl_group
    
    if col >= mark_col and col < end_col then
      if hl_group == expected_group then
        found = true
        break
      end
    end
  end
  
  if not found then
    M.log("Extmarks found in buffer (ns " .. ns_id .. "):")
    local all_marks = vim.api.nvim_buf_get_extmarks(buf, ns_id, 0, -1, {details = true})
    for _, mark in ipairs(all_marks) do
      local mark_line = mark[2]
      local mark_col = mark[3]
      local details = mark[4]
      M.log(string.format("  - Line: %d, Col: %d-%d, Group: %s", mark_line, mark_col, details.end_col, details.hl_group))
    end
    error(string.format("❌ Expected highlight '%s' at line %d, col %d. Found nothing or different group.", 
      expected_group, line, col))
  end
  M.log("  ✓ Found highlight " .. expected_group .. " at " .. line .. ":" .. col)
end

-- TESTS

function M.test_symbol_training()
  M.log("🧪 Testing Symbol Training...")
  local SymbolTraining = require('typing_kata.modes.symbol_training')
  local player = require('typing_kata.core.player').new_player("TestUser")
  local mode = SymbolTraining:new(player)
  
  mode:start()
  local buf = M.assert_buffer_ready(mode, true)
  
  -- Verify initial highlights
  -- The cursor is at CURSOR_POSITION (40). So col 44 (5 spaces prefix + 39).
  -- Wait, render_section adds 5 spaces. render_typing_line puts cursor at col 40 (1-based).
  -- So 0-based col 39.
  -- Plus 5 spaces prefix -> col 44.
  -- Let's check a future character (right of cursor)
  -- Display: 5 spaces + ... text ...
  -- Cursor is at index 40 of text.
  -- Text line is usually line 3 or 4 of buffer.
  -- In symbol training: Title, =, blank. Line 4 is text?
  -- Let's find the text line.
  local text_line_idx = -1
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    M.log(string.format("Line %d: '%s'", i, line))
    if line:find("▼") then
      M.log("  -> Found Top Cursor at Line " .. i)
      -- New layout:
      -- Line i: ▼ (Top Cursor)
      -- Line i+1: Text
      -- Line i+2: ▲ (Bottom Cursor)
      
      -- We want 0-based index of Text line.
      -- If 'i' is 1-based index of top cursor (e.g. 8)
      -- Text is at i+1 (e.g. 9) (1-based)
      -- Text is at i (e.g. 8) (0-based)
      text_line_idx = i 
      break
    end
  end
  
  if text_line_idx == -1 then error("Could not find text line") end
  
  -- Check future character (at cursor position + 1)
  -- Cursor is at col 44 (5 prefix + 39).
  -- Char at 44 should be TypingKataUntyped (Current char is Untyped)
  M.assert_highlight(buf, text_line_idx, 44, "TypingKataUntyped")
  
  -- Simulate WRONG input
  M.log("  Simulating WRONG input 'X'...")
  mode:handle_char('X') -- Wrong char
  
  -- Now the text should have shifted left.
  -- The character that was at 44 is now at 43 (left of cursor).
  -- It should be highlighted as Error.
  M.assert_highlight(buf, text_line_idx, 43, "TypingKataError")
  
  -- Check new current character
  M.assert_highlight(buf, text_line_idx, 44, "TypingKataUntyped")
  
  mode:exit()
end

function M.test_snake_apple()
  M.log("🧪 Testing Snake Apple...")
  local SnakeApple = require('typing_kata.modes.snake_apple')
  local player = require('typing_kata.core.player').new_player("TestUser")
  local mode = SnakeApple:new(player)
  
  mode:start()
  local buf = M.assert_buffer_ready(mode, true) -- SnakeApple overrides to true
  
  -- Check if apples rendered
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local found_apple = false
  for _, line in ipairs(lines) do
    if line:find("🍎") then found_apple = true break end
  end
  
  if not found_apple then
    error("❌ No apples found in Snake Apple buffer")
  end
  M.log("  ✓ Apples rendered")
  
  mode:exit()
end

function M.test_vim_motions()
  M.log("🧪 Testing Vim Motions...")
  local VimMotions = require('typing_kata.modes.vim_motions')
  local player = require('typing_kata.core.player').new_player("TestUser")
  local mode = VimMotions:new(player)
  
  mode:start()
  M.assert_buffer_ready(mode, true) -- Should be true now
  
  mode:exit()
end

function M.run()
  local status, err = pcall(function()
    M.setup()
    M.test_symbol_training()
    M.test_snake_apple()
    M.test_vim_motions()
    M.log("✅ All System Tests Passed!")
  end)
  
  if not status then
    M.log("❌ CRITICAL FAILURE: " .. tostring(err))
    if log_file then log_file:close() end
    os.exit(1)
  end
  
  M.teardown()
end

-- Run if executing this file
M.run()

return M
