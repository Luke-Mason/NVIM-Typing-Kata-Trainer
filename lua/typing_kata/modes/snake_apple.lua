-- Snake Apple Mode: Navigate code with real vim motions to find apples
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')
local code_samples = require('typing_kata.core.code_samples')

local SnakeApple = setmetatable({}, { __index = BaseMode })

function SnakeApple:new(player)
  local obj = BaseMode:new(player, 'snake_apple')
  setmetatable(obj, { __index = self })

  obj.apples_per_round = 5  -- 5 apples per code file
  obj.rounds_per_session = 3  -- 3 different code files
  obj.current_round = 1
  obj.apples_found = 0
  obj.total_apples_found = 0

  obj.apple_positions = {}  -- Store line numbers where apples are hidden
  obj.buffer_lines = {}
  obj.current_sample = nil
  obj.first_render = true  -- Track if this is the first render

  return obj
end

function SnakeApple:setup()
  -- Nothing special
end

function SnakeApple:generate_task()
  if self.current_round > self.rounds_per_session then
    -- Session complete
    self:exit()
    return
  end

  -- Pick random code sample
  self.current_sample = code_samples.samples[math.random(#code_samples.samples)]

  -- Split code into lines
  self.buffer_lines = {}
  for line in self.current_sample.code:gmatch("[^\r\n]+") do
    table.insert(self.buffer_lines, line)
  end

  -- Pick 5 random lines to hide apples (avoid empty lines and first/last few lines)
  self.apple_positions = {}
  local valid_lines = {}
  for i = 5, #self.buffer_lines - 5 do
    local line = self.buffer_lines[i]
    -- Only pick lines with actual content (not just whitespace/braces)
    if line:match("%S") and #line > 10 then
      table.insert(valid_lines, i)
    end
  end

  -- Pick 5 random positions
  if #valid_lines >= 5 then
    local used = {}
    for i = 1, self.apples_per_round do
      local idx
      repeat
        idx = math.random(1, #valid_lines)
      until not used[idx]
      used[idx] = true

      local line_num = valid_lines[idx]
      table.insert(self.apple_positions, line_num)

      -- Insert apple at a random word position in the line
      local line = self.buffer_lines[line_num]
      local words = {}
      local positions = {}
      local current_pos = 1

      -- Find all word positions
      for word in line:gmatch("%S+") do
        local start = line:find(word, current_pos, true)
        if start then
          table.insert(words, word)
          table.insert(positions, start)
          current_pos = start + #word
        end
      end

      if #words > 0 then
        -- Pick a word in the middle (not first or last)
        local word_idx = math.random(math.max(2, math.floor(#words * 0.3)), math.min(#words - 1, math.floor(#words * 0.7)))
        local insert_pos = positions[word_idx]

        -- Insert apple emoji before the word
        self.buffer_lines[line_num] = line:sub(1, insert_pos - 1) .. "🍎 " .. line:sub(insert_pos)
      end
    end
  end

  self.apples_found = 0
end

function SnakeApple:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
  vim.api.nvim_win_set_option(0, 'wrap', false)
end

function SnakeApple:setup_buffer_keymaps()
  local opts = { buffer = self.buffer, noremap = true, silent = true }

  vim.keymap.set('n', 'q', function() self:exit() end, opts)
  vim.keymap.set('n', '<Esc>', function() self:exit() end, opts)

  self:add_autocmd('CursorMoved', {
    buffer = self.buffer,
    callback = function()
      self:on_cursor_move()
    end
  })
end

function SnakeApple:on_cursor_move()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  -- Account for header (5 lines)
  local code_line = row - 5

  if code_line > 0 and code_line <= #self.buffer_lines then
    local line = self.buffer_lines[code_line]

    -- Check if this line has an apple
    if line and line:find("🍎") then
      local search_pos = 1
      while true do
        -- Find byte position of next apple starting from search_pos
        local apple_start, apple_end = line:find("🍎", search_pos)
        if not apple_start then break end

        -- The emoji 🍎 is 4 bytes in UTF-8
        -- Check if cursor is within the first byte of the emoji only
        -- apple_start is 1-indexed in Lua, col is 0-indexed in Neovim
        if col == apple_start - 1 then
          -- Check if this apple hasn't been collected yet
          -- (Though if it's in the buffer line, it hasn't been collected from logic POV)
          
          -- Double check it's a valid apple line (logic redundancy but safe)
          local is_apple_line = false
          for _, found_line in ipairs(self.apple_positions) do
            if found_line == code_line then
              is_apple_line = true
              break
            end
          end

          if is_apple_line then
            -- Replace apple with a space
            self.buffer_lines[code_line] = line:sub(1, apple_start - 1) .. " " .. line:sub(apple_end + 1)

            self.apples_found = self.apples_found + 1
            self.total_apples_found = self.total_apples_found + 1

            -- Award XP
            local xp = self:calculate_xp()
            session.add_task_completion(self.session, xp)
            session.increment_streak(self.session)

            vim.notify(string.format('🍎 Apple %d/%d found! (+%d XP)',
              self.apples_found, self.apples_per_round, xp), vim.log.levels.INFO)

            -- Update the buffer line without re-rendering entire buffer
            local buffer_line_num = row
            vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
            vim.api.nvim_buf_set_lines(self.buffer, buffer_line_num - 1, buffer_line_num, false, {self.buffer_lines[code_line]})
            vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)

            -- Check if round complete
            if self.apples_found >= self.apples_per_round then
              vim.defer_fn(function()
                if self.is_running then
                  self.current_round = self.current_round + 1
                  if self.current_round <= self.rounds_per_session then
                    vim.notify('Round complete! New code file loaded...', vim.log.levels.INFO)
                    self.first_render = true  -- Reset cursor position for new round
                    self:generate_task()
                    self:render()
                  else
                    self:exit()
                  end
                end
              end, 1000)
            end

            -- Break inner loop as we modified the line
            break
          end
        end

        -- Move search position past this apple
        search_pos = apple_end + 1
      end
    end
  end

  self:update_header()
end

function SnakeApple:update_header()
  if not self.buffer or not vim.api.nvim_buf_is_valid(self.buffer) then
    return
  end

  local stats_line = string.format('🐍 %s | Round: %d/%d | Apples: %d/%d | Total: %d | Streak: %d | XP: %d',
    self.current_sample.name,
    self.current_round, self.rounds_per_session,
    self.apples_found, self.apples_per_round,
    self.total_apples_found,
    self.session.current_streak, self.session.xp_earned)

  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(self.buffer, 1, 2, false, {stats_line})
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function SnakeApple:update(key)
  return false
end

function SnakeApple:render()
  if not self.current_sample then
    return
  end

  local lines = {}

  -- Header
  table.insert(lines, '')
  table.insert(lines, string.format('🐍 %s | Round: %d/%d | Apples: %d/%d | Total: %d | Streak: %d | XP: %d',
    self.current_sample.name,
    self.current_round, self.rounds_per_session,
    self.apples_found, self.apples_per_round,
    self.total_apples_found,
    self.session.current_streak, self.session.xp_earned))
  table.insert(lines, '')
  table.insert(lines, 'Navigate code to find 5 hidden 🍎 apples! Use: %%, ]], [[, {}, /🍎, f🍎, w/b/e, etc.')
  table.insert(lines, '')

  -- Add code with apples
  for _, line in ipairs(self.buffer_lines) do
    table.insert(lines, line)
  end

  table.insert(lines, '')

  -- Add consistent controls legend
  local controls = self:render_controls_legend({
    {key = 'Vim Motions', desc = 'Navigate to find apples (h/j/k/l, w/b/e, %%, ]], [[, {}, f🍎, /🍎, etc.)'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)

  -- Set filetype for syntax highlighting
  vim.api.nvim_buf_set_option(self.buffer, 'filetype', self.current_sample.filetype)

  -- Only position cursor on first render or when loading new round
  if self.first_render then
    vim.api.nvim_win_set_cursor(0, {6, 0})
    self.first_render = false
  end
end

function SnakeApple:calculate_xp()
  local base_xp = 10
  return xp_module.calculate(base_xp, {
    accuracy = 100,
    streak = self.session.current_streak,
  })
end

function SnakeApple:exit()
  vim.api.nvim_win_set_option(0, 'wrap', true)
  BaseMode.exit(self)
end

return SnakeApple
