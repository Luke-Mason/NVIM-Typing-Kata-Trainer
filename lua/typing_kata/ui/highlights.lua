-- Highlight groups for typing-kata
local M = {}

-- Define highlight groups
function M.setup()
  -- Title highlights
  vim.api.nvim_set_hl(0, 'TypingKataTitle', { fg = '#cba6f7', bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataHeader', { fg = '#f9e2af', bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataBorder', { fg = '#6c7086' })
  vim.api.nvim_set_hl(0, 'TypingKataAccent', { fg = '#94e2d5', bold = true })

  -- Stats highlights
  vim.api.nvim_set_hl(0, 'TypingKataSuccess', { fg = '#a6e3a1', bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataError', { fg = '#f38ba8', bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataWarning', { fg = '#fab387' })
  vim.api.nvim_set_hl(0, 'TypingKataInfo', { fg = '#89dceb' })
  vim.api.nvim_set_hl(0, 'TypingKataStatLabel', { fg = '#89b4fa' })
  vim.api.nvim_set_hl(0, 'TypingKataStatValue', { fg = '#f5c2e7', bold = true })

  -- Typing highlights
  vim.api.nvim_set_hl(0, 'TypingKataCorrect', { fg = '#a6e3a1', bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataIncorrect', { fg = '#f38ba8', bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataTarget', { fg = '#cdd6f4' })

  -- Rank highlights
  vim.api.nvim_set_hl(0, 'TypingKataRank', { fg = '#cba6f7', bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataXP', { fg = '#f9e2af', bold = true })

  -- Menu highlights
  vim.api.nvim_set_hl(0, 'TypingKataMenuItem', { fg = '#89dceb' })
  vim.api.nvim_set_hl(0, 'TypingKataMenuNumber', { fg = '#f9e2af', bold = true })

  -- Progress highlights
  vim.api.nvim_set_hl(0, 'TypingKataProgress', { fg = '#a6e3a1', bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataProgressBg', { fg = '#45475a' })
end

-- Apply highlights to buffer based on patterns
function M.apply_highlights(buf, lines)
  for i, line in ipairs(lines) do
    local line_idx = i - 1

    -- Highlight borders
    if line:match('^═+') or line:match('^─+') or line:match('╔') or line:match('║') or line:match('╚') or line:match('╝') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataBorder', line_idx, 0, -1)
    end

    -- Highlight titles with emojis
    if line:match('🎯') or line:match('🔧') or line:match('📝') or line:match('⚡') or line:match('🐍') or line:match('🔣') or line:match('💻') or line:match('🎓') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataTitle', line_idx, 0, -1)
    end

    -- Highlight stats
    local stat_start, stat_end = line:find('Accuracy:')
    if stat_start then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatLabel', line_idx, stat_start - 1, stat_end)
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatValue', line_idx, stat_end, -1)
    end

    stat_start, stat_end = line:find('Streak:')
    if stat_start then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatLabel', line_idx, stat_start - 1, stat_end)
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatValue', line_idx, stat_end, -1)
    end

    stat_start, stat_end = line:find('XP')
    if stat_start and line:match('XP:') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatLabel', line_idx, stat_start - 1, stat_end + 1)
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatValue', line_idx, stat_end + 1, -1)
    end

    stat_start, stat_end = line:find('WPM:')
    if stat_start then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatLabel', line_idx, stat_start - 1, stat_end)
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatValue', line_idx, stat_end, -1)
    end

    -- Highlight success markers
    if line:match('✓') or line:match('CORRECT') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataSuccess', line_idx, 0, -1)
    end

    -- Highlight error markers
    if line:match('✗') or line:match('Wrong') or line:match('ERROR') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataError', line_idx, 0, -1)
    end

    -- Highlight hints
    if line:match('💡') or line:match('Hint') or line:match('Tip:') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataInfo', line_idx, 0, -1)
    end

    -- Highlight section headers
    if line:match('TASK:') or line:match('COMMAND:') or line:match('Question') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataAccent', line_idx, 0, -1)
    end

    -- Highlight input labels
    if line:match('YOUR ANSWER:') or line:match('YOUR KEYBINDING:') or line:match('You typed:') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataHeader', line_idx, 0, -1)
    end

    -- Highlight CONTROLS section
    if line:match('CONTROLS') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataTitle', line_idx, 0, -1)
    end
  end
end

return M
