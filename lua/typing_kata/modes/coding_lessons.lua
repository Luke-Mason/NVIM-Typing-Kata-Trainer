-- Coding Lessons Mode: Type real code snippets
local WordTyping = require('typing_kata.modes.word_typing')
local code_samples = require('typing_kata.core.code_samples')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local typing_display = require('typing_kata.ui.typing_display')

local CodingLessons = setmetatable({}, { __index = WordTyping })

function CodingLessons:new(player, language_filter)
  local obj = WordTyping:new(player)
  obj.mode_name = 'coding_lessons'
  obj.language_filter = language_filter  -- nil for random, or specific filetype like 'python', 'go', etc.
  setmetatable(obj, { __index = self })
  return obj
end

function CodingLessons:generate_task()
  -- Filter samples by language if specified
  local available_samples = {}
  if self.language_filter then
    for _, sample in ipairs(code_samples.samples) do
      if sample.filetype == self.language_filter then
        table.insert(available_samples, sample)
      end
    end
  else
    available_samples = code_samples.samples
  end

  -- If no samples match filter, fall back to all samples
  if #available_samples == 0 then
    available_samples = code_samples.samples
  end

  local sample = available_samples[math.random(#available_samples)]
  self.target_text = sample.code:gsub("\r\n", "\n")
  self.sample_name = sample.name
  self.sample_filetype = sample.filetype
  self.indent_size = sample.indent or 4  -- Default to 4 if not specified

  self.typed_text = ""
  self.current_char_idx = 0
  self.errors = {}
end

function CodingLessons:setup_buffer_keymaps()
  WordTyping.setup_buffer_keymaps(self)
  local opts = { buffer = self.buffer, noremap = true, silent = true }

  -- Handle Enter
  vim.keymap.set('i', '<CR>', function() return self:handle_char('\n') end, opts)

  -- Handle Tab - insert spaces based on sample's indent size
  vim.keymap.set('i', '<Tab>', function()
    local s = ""
    for _=1,(self.indent_size or 4) do
      s = s .. self:handle_char(' ')
    end
    return s
  end, opts)

  -- Skip to next sample (Ctrl+N in normal mode)
  vim.keymap.set('n', '<C-n>', function()
    self:generate_task()
    self:render()
  end, opts)
end

function CodingLessons:render()
  local lines = {}
  
  -- Header
  table.insert(lines, '')
  local mode_title = '💻 CODING LESSONS'
  if self.language_filter then
    mode_title = mode_title .. ' [' .. self.language_filter:upper() .. ']'
  end
  table.insert(lines, '     ' .. mode_title .. ': ' .. (self.sample_name or 'Unknown'))
  table.insert(lines, '     =================================')
  table.insert(lines, '')
  
  -- Stats
  local wpm = self:calculate_wpm()
  local accuracy = session.calculate_accuracy(self.session)
  table.insert(lines, string.format('     WPM: %.1f | Acc: %.1f%% | Errors: %d', wpm, accuracy, self.session.error_count))
  table.insert(lines, '')

  local header_height = #lines

  -- Render Code using 2D Carousel
  local display_lines, highlights = typing_display.render_typing_page(
    self.target_text,
    self.current_char_idx,
    self.errors,
    11 -- Viewport height
  )
  
  -- Add typing display lines with 5 spaces margin
  local margin = '     '
  for _, line in ipairs(display_lines) do
    table.insert(lines, margin .. line)
  end
  
  -- Footer / Controls
  table.insert(lines, '')
  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type the code exactly'},
    {key = 'ENTER', desc = 'New line'},
    {key = 'TAB', desc = (self.indent_size or 4) .. ' spaces'},
    {key = 'Ctrl+N', desc = 'Skip to next'},
    {key = 'ESC', desc = 'Exit'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
  
  -- Apply Highlights
  -- Shift columns by 5 due to margin
  local shifted_highlights = {}
  for _, hl in ipairs(highlights) do
    table.insert(shifted_highlights, {
      line = hl.line,
      col_start = hl.col_start + 5,
      col_end = hl.col_end + 5,
      hl_group = hl.hl_group
    })
  end
  
  typing_display.apply_highlights(self.buffer, shifted_highlights, header_height)
end

return CodingLessons
