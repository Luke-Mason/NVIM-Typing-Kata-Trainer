-- Highlight groups for typing-kata
-- Palette: Catppuccin-inspired
local M = {}

-- Palette definitions
local colors = {
  rosewater = '#f5e0dc',
  flamingo  = '#f2cdcd',
  pink      = '#f5c2e7',
  mauve     = '#cba6f7',
  red       = '#f38ba8',
  maroon    = '#eba0ac',
  peach     = '#fab387',
  yellow    = '#f9e2af',
  green     = '#a6e3a1',
  teal      = '#94e2d5',
  sky       = '#89dceb',
  sapphire  = '#74c7ec',
  blue      = '#89b4fa',
  lavender  = '#b4befe',
  text      = '#cdd6f4',
  subtext1  = '#bac2de',
  subtext0  = '#a6adc8',
  overlay2  = '#9399b2',
  overlay1  = '#7f849c',
  overlay0  = '#6c7086',
  surface2  = '#585b70',
  surface1  = '#45475a',
  surface0  = '#313244',
  base      = '#1e1e2e',
  mantle    = '#181825',
  crust     = '#11111b',
}

-- Define highlight groups
function M.setup()
  -- General UI
  vim.api.nvim_set_hl(0, 'TypingKataTitle', { fg = colors.mauve, bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataSubtitle', { fg = colors.lavender, italic = true })
  vim.api.nvim_set_hl(0, 'TypingKataHeader', { fg = colors.blue, bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataBorder', { fg = colors.overlay0 })
  vim.api.nvim_set_hl(0, 'TypingKataAccent', { fg = colors.peach, bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataDim', { fg = colors.overlay1 })
  
  -- Stats
  vim.api.nvim_set_hl(0, 'TypingKataSuccess', { fg = colors.green, bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataError', { fg = colors.red, bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataWarning', { fg = colors.yellow })
  vim.api.nvim_set_hl(0, 'TypingKataInfo', { fg = colors.sky })
  vim.api.nvim_set_hl(0, 'TypingKataStatLabel', { fg = colors.subtext0 })
  vim.api.nvim_set_hl(0, 'TypingKataStatValue', { fg = colors.text, bold = true })
  
  -- Game / Typing
  vim.api.nvim_set_hl(0, 'TypingKataCorrect', { fg = colors.green })
  vim.api.nvim_set_hl(0, 'TypingKataIncorrect', { fg = colors.red, underline = true })
  vim.api.nvim_set_hl(0, 'TypingKataTarget', { fg = colors.text, bg = colors.surface1 }) -- Cursor/Current char
  vim.api.nvim_set_hl(0, 'TypingKataUntyped', { fg = colors.overlay0 })
  
  -- Ranks & Progression
  vim.api.nvim_set_hl(0, 'TypingKataRank', { fg = colors.mauve, bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataXP', { fg = colors.yellow })
  vim.api.nvim_set_hl(0, 'TypingKataProgress', { fg = colors.green })
  vim.api.nvim_set_hl(0, 'TypingKataProgressBg', { fg = colors.surface1 })
  
  -- Menu Specific
  vim.api.nvim_set_hl(0, 'TypingKataKey', { fg = colors.pink, bold = true })
  vim.api.nvim_set_hl(0, 'TypingKataMenuItem', { fg = colors.text })
  vim.api.nvim_set_hl(0, 'TypingKataSection', { fg = colors.teal, bold = true, underline = true })
end

-- Apply highlights to buffer based on patterns
function M.apply_highlights(buf, lines)
  for i, line in ipairs(lines) do
    local line_idx = i - 1

    -- Highlight borders (using Box Drawing characters)
    if line:match('^[─═╭╮╰╯│]+$') or line:match('^[─═]+$') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataBorder', line_idx, 0, -1)
    end

    -- Highlight Keys in brackets [key]
    for s, e in line:gmatch('()%[%w+%]%s()') do
       -- This is simplified; proper parsing would be better but this works for basic lists
       -- Adding highlights for [1], [q], etc.
    end
    -- Better pattern matching for keys
    local key_pattern = '%[([%w%-]+)%]'
    local s, e = line:find(key_pattern)
    while s do
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataDim', line_idx, s-1, s) -- [
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataKey', line_idx, s, e-1) -- Key
      vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataDim', line_idx, e-1, e) -- ]
      s, e = line:find(key_pattern, e + 1)
    end

    -- Titles / Headers
    if line:match('^%s*Main Menu') or line:match('^%s*Statistics') then
       vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataTitle', line_idx, 0, -1)
    end
    
    -- Section Headers (e.g. "Fundamentals", "Modes")
    if line:match('^%s*╭─') then -- Start of a section box
       -- Ignore
    elseif line:match('^%s*│%s+[A-Z][A-Z%s]+%s*│') then -- Boxed Title
       vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataSection', line_idx, 0, -1)
    end

    -- Stats pairs "Label: Value"
    local label_pat = '([%w%s]+):%s*([%w%%%.]+)'
    for s, label, val, e in line:gmatch('()([%w%s]+):%s*([%w%%%.]+)()') do
       -- Find position of label
       local label_s, label_e = line:find(label, s, true)
       if label_s then
         vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatLabel', line_idx, label_s-1, label_e)
       end
       
       local val_s, val_e = line:find(val, label_e, true)
       if val_s then
         vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataStatValue', line_idx, val_s-1, val_e)
       end
    end
    
    -- Specific icons/markers
    if line:match('✓') then vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataSuccess', line_idx, 0, -1) end
    if line:match('✗') then vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataError', line_idx, 0, -1) end
    if line:match('💡') then vim.api.nvim_buf_add_highlight(buf, -1, 'TypingKataInfo', line_idx, 0, -1) end
  end
end

return M
