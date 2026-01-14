-- Coding Lessons Mode: Type real code snippets
local WordTyping = require('typing_kata.modes.word_typing')
local code_samples = require('typing_kata.core.code_samples')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local typing_display = require('typing_kata.ui.typing_display')

local CodingLessons = setmetatable({}, { __index = WordTyping })

function CodingLessons:new(player)
  local obj = WordTyping:new(player)
  obj.mode_name = 'coding_lessons'
  setmetatable(obj, { __index = self })
  return obj
end

function CodingLessons:generate_task()
  local sample = code_samples.samples[math.random(#code_samples.samples)]
  self.target_text = sample.code:gsub("\r\n", "\n")
  self.sample_name = sample.name
  self.sample_filetype = sample.filetype
  
  self.typed_text = ""
  self.current_char_idx = 0
  self.errors = {}
end

function CodingLessons:setup_buffer_keymaps()
  WordTyping.setup_buffer_keymaps(self)
  local opts = { buffer = self.buffer, noremap = true, silent = true }
  
  -- Handle Enter
  vim.keymap.set('i', '<CR>', function() return self:handle_char('\n') end, opts)
  
  -- Handle Tab (convert to 4 spaces to match many samples, or handle literal tab)
  -- For simplicity, let's treat tab as 4 spaces if the code has spaces, 
  -- but our samples use spaces. Let's just map Tab to handle ' ' 4 times?
  -- Or just map Tab to literal \t? 
  -- Most samples look like they use spaces.
  -- Let's stick to simple character matching. If the user presses Tab, and the code has 4 spaces, 
  -- it should probably fail or we handle it smart. 
  -- "The less code the better": Let's assume the user types spaces. 
  -- But usually in vim you press Tab.
  -- Let's map Tab to inserted 4 spaces for convenience.
  vim.keymap.set('i', '<Tab>', function() 
    local s = ""
    for _=1,4 do s = s .. self:handle_char(' ') end
    return s
  end, opts)
end

function CodingLessons:render()
  local lines = {}
  
  -- Header
  table.insert(lines, '')
  table.insert(lines, '     💻 CODING LESSONS: ' .. (self.sample_name or 'Unknown'))
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
    9 -- Viewport height (odd number for centering)
  )
  
  -- Add typing display lines
  for _, line in ipairs(display_lines) do
    table.insert(lines, '     ' .. line)
  end
  
  -- Footer / Controls
  table.insert(lines, '')
  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type the code exactly'},
    {key = 'ENTER', desc = 'New line'},
    {key = 'TAB', desc = '4 spaces'},
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
