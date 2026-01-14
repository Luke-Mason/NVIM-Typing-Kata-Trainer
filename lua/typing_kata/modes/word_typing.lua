-- Word Typing Mode: Monkeytype-style paragraph typing with WPM tracking
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')
local typing_display = require('typing_kata.ui.typing_display')

local WordTyping = setmetatable({}, { __index = BaseMode })

-- Paragraphs for typing practice
WordTyping.PARAGRAPHS = {
  "The quick brown fox jumps over the lazy dog near the riverbank where the old willow tree stands tall and proud against the evening sky.",
  "Programming requires patience and practice to master the intricate dance between logic and creativity that defines software development.",
  "Learning vim motions transforms your editing workflow from a slow crawl to a lightning fast dance across the codebase with precision.",
  "The morning sun cast long shadows across the empty street as she walked purposefully toward her destination with determination.",
  "Technology evolves rapidly but the fundamental principles of good design and clear communication remain constant across generations.",
  "Mountains rise majestically in the distance while clouds drift lazily overhead painting shadows on the valley floor below.",
  "Writing clean code is not just about making it work but about making it readable maintainable and elegant for future developers.",
  "The ocean waves crashed rhythmically against the shore as seagulls circled overhead calling out to each other in the salty air.",
  "Debugging is twice as hard as writing the code in the first place so if you write the code as cleverly as possible you are not smart enough to debug it.",
  "Practice makes perfect but perfect practice makes mastery so focus on deliberate practice rather than mindless repetition of tasks.",
}

function WordTyping:new(player)
  local obj = BaseMode:new(player, 'word_typing')
  setmetatable(obj, { __index = self })

  obj.target_text = ""
  obj.typed_text = ""
  obj.current_char_idx = 0
  obj.start_time = nil
  obj.errors = {}  -- Track error positions

  return obj
end

function WordTyping:setup()
  self.start_time = os.time()
end

function WordTyping:generate_task()
  -- Pick a random paragraph
  self.target_text = self.PARAGRAPHS[math.random(#self.PARAGRAPHS)]
  self.typed_text = ""
  self.current_char_idx = 0
  self.errors = {}
end

function WordTyping:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function WordTyping:setup_buffer_keymaps()
  BaseMode.setup_buffer_keymaps(self)

  -- Enter insert mode automatically
  vim.schedule(function()
    if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
      vim.cmd('startinsert')
    end
  end)

  local opts = { buffer = self.buffer, noremap = true, silent = true }

  -- Map all printable characters
  local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local symbols = '`~!@#$%^&*()-_=+[{]}\\|;:\'",<.>/?'

  for i = 1, #chars do
    local char = chars:sub(i, i)
    vim.keymap.set('i', char, function() return self:handle_char(char) end, opts)
  end

  for i = 1, #symbols do
    local char = symbols:sub(i, i)
    vim.keymap.set('i', char, function() return self:handle_char(char) end, opts)
  end

  vim.keymap.set('i', '<Space>', function() return self:handle_char(' ') end, opts)
  vim.keymap.set('i', '<BS>', function() return self:backspace() end, opts)
end

function WordTyping:handle_char(char)
  if self.current_char_idx >= #self.target_text then
    return ''  -- Already finished
  end

  local expected_char = self.target_text:sub(self.current_char_idx + 1, self.current_char_idx + 1)

  if char == expected_char then
    self.typed_text = self.typed_text .. char
    self.current_char_idx = self.current_char_idx + 1
    session.record_keystroke(self.session, true)
    self.errors[self.current_char_idx] = nil  -- Clear error if corrected
  else
    -- Wrong character
    self.typed_text = self.typed_text .. char
    self.current_char_idx = self.current_char_idx + 1
    self.errors[self.current_char_idx] = true
    session.record_keystroke(self.session, false)
    session.break_streak(self.session)
  end

  -- Check if completed
  if self.current_char_idx >= #self.target_text then
    local xp = self:calculate_xp()
    session.add_task_completion(self.session, xp)

    -- Small delay then exit
    vim.defer_fn(function()
      if self.is_running then
        self:exit()
      end
    end, 500)
  end

  self:render()
  return ''
end

function WordTyping:backspace()
  if self.current_char_idx > 0 then
    self.current_char_idx = self.current_char_idx - 1
    self.typed_text = self.typed_text:sub(1, -2)
    self:render()
  end
  return ''
end

function WordTyping:update(key)
  return false
end

function WordTyping:calculate_wpm()
  local elapsed = os.time() - self.start_time
  if elapsed == 0 then
    return 0
  end
  return xp_module.calculate_wpm(self.current_char_idx, elapsed)
end

function WordTyping:render()
  local lines = {}

  -- Title
  table.insert(lines, '')
  table.insert(lines, '          📝 WORD TYPING - WPM TRAINING')
  table.insert(lines, '          ================================')
  table.insert(lines, '')

  -- Progress
  local progress = math.floor((self.current_char_idx / #self.target_text) * 100)
  table.insert(lines, string.format('     Progress: %d%% (%d/%d chars)',
    progress, self.current_char_idx, #self.target_text))
  table.insert(lines, '')
  table.insert(lines, '')

  -- Typing display using monkeytype-style component
  local display_section = typing_display.render_section(
    self.target_text,
    self.current_char_idx,
    self.errors,
    nil  -- No additional title
  )

  -- Add typing display lines
  local current_line_count = #lines
  for _, line in ipairs(display_section.lines) do
    table.insert(lines, line)
  end

  table.insert(lines, '')

  -- Stats
  local wpm = self:calculate_wpm()
  local accuracy = session.calculate_accuracy(self.session)
  table.insert(lines, string.format('     Current WPM: %.1f', wpm))
  table.insert(lines, string.format('     Accuracy: %.1f%%', accuracy))
  table.insert(lines, string.format('     Errors: %d', self.session.error_count))
  table.insert(lines, '')

  -- Add consistent controls legend
  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type the text as it appears (cursor stays in middle)'},
    {key = 'BACKSPACE', desc = 'Delete last character'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)

  -- Apply highlights
  local total_offset = current_line_count + display_section.highlight_line_offset
  typing_display.apply_highlights(self.buffer, display_section.highlights, total_offset)
end

function WordTyping:calculate_xp()
  local base_xp = 100  -- Full paragraph = more XP

  local accuracy = session.calculate_accuracy(self.session)
  local wpm = self:calculate_wpm()

  return xp_module.calculate(base_xp, {
    accuracy = accuracy,
    wpm = wpm,
    streak = self.session.current_streak,
  })
end

return WordTyping
