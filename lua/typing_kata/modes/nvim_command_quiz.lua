-- Neovim Command Quiz: Given a plugin command/tool, type your keybinding
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')
local keymap_parser = require('typing_kata.core.keymap_parser')

local NvimCommandQuiz = setmetatable({}, { __index = BaseMode })

-- Common Neovim plugin commands and typical keybindings
-- command_key links to keymap_parser patterns for auto-detection
NvimCommandQuiz.COMMANDS = {
  -- Telescope
  {desc = "Find files (Telescope)", answer = "<leader>ff", plugin = "telescope", command_key = "telescope_find_files"},
  {desc = "Live grep (Telescope)", answer = "<leader>fg", plugin = "telescope", command_key = "telescope_live_grep"},
  {desc = "Find buffers (Telescope)", answer = "<leader>fb", plugin = "telescope", command_key = "telescope_buffers"},
  {desc = "Find help tags (Telescope)", answer = "<leader>fh", plugin = "telescope", command_key = "telescope_help_tags"},
  {desc = "Recent files (Telescope)", answer = "<leader>fr", plugin = "telescope", command_key = "telescope_recent_files"},

  -- LSP
  {desc = "Go to definition (LSP)", answer = "gd", plugin = "lsp", command_key = "lsp_goto_definition"},
  {desc = "Go to declaration (LSP)", answer = "gD", plugin = "lsp", command_key = "lsp_goto_declaration"},
  {desc = "Show hover documentation (LSP)", answer = "K", plugin = "lsp", command_key = "lsp_hover"},
  {desc = "Go to implementation (LSP)", answer = "gi", plugin = "lsp", command_key = "lsp_goto_implementation"},
  {desc = "Show signature help (LSP)", answer = "<C-k>", plugin = "lsp", command_key = "lsp_signature_help"},
  {desc = "Rename symbol (LSP)", answer = "<leader>rn", plugin = "lsp", command_key = "lsp_rename"},
  {desc = "Code action (LSP)", answer = "<leader>ca", plugin = "lsp", command_key = "lsp_code_action"},
  {desc = "Show references (LSP)", answer = "gr", plugin = "lsp", command_key = "lsp_references"},
  {desc = "Format document (LSP)", answer = "<leader>f", plugin = "lsp", command_key = "lsp_format"},

  -- Git (fugitive/gitsigns)
  {desc = "Git status", answer = "<leader>gs", plugin = "git", command_key = "git_status"},
  {desc = "Git commit", answer = "<leader>gc", plugin = "git"},
  {desc = "Git blame line", answer = "<leader>gb", plugin = "git", command_key = "git_blame_line"},
  {desc = "Next git hunk", answer = "]c", plugin = "git", command_key = "git_next_hunk"},
  {desc = "Previous git hunk", answer = "[c", plugin = "git", command_key = "git_prev_hunk"},
  {desc = "Stage hunk", answer = "<leader>hs", plugin = "git", command_key = "git_stage_hunk"},
  {desc = "Reset hunk", answer = "<leader>hr", plugin = "git", command_key = "git_reset_hunk"},

  -- File tree (nvim-tree/neo-tree)
  {desc = "Toggle file tree", answer = "<leader>e", plugin = "filetree", command_key = "toggle_file_tree"},
  {desc = "Find current file in tree", answer = "<leader>ef", plugin = "filetree", command_key = "find_file_in_tree"},

  -- Terminal
  {desc = "Toggle terminal", answer = "<leader>t", plugin = "terminal", command_key = "toggle_terminal"},
  {desc = "Toggle floating terminal", answer = "<A-i>", plugin = "terminal"},

  -- Navigation
  {desc = "Next buffer", answer = "<leader>bn", plugin = "navigation", command_key = "next_buffer"},
  {desc = "Previous buffer", answer = "<leader>bp", plugin = "navigation", command_key = "prev_buffer"},
  {desc = "Close buffer", answer = "<leader>bd", plugin = "navigation", command_key = "close_buffer"},
  {desc = "Split window vertically", answer = "<leader>sv", plugin = "navigation"},
  {desc = "Split window horizontally", answer = "<leader>sh", plugin = "navigation"},

  -- Debug (DAP)
  {desc = "Start/continue debugging", answer = "<F5>", plugin = "dap", command_key = "dap_continue"},
  {desc = "Step over", answer = "<F10>", plugin = "dap", command_key = "dap_step_over"},
  {desc = "Step into", answer = "<F11>", plugin = "dap", command_key = "dap_step_into"},
  {desc = "Step out", answer = "<F12>", plugin = "dap", command_key = "dap_step_out"},
  {desc = "Toggle breakpoint", answer = "<leader>db", plugin = "dap", command_key = "dap_toggle_breakpoint"},

  -- Completion
  {desc = "Trigger completion", answer = "<C-Space>", plugin = "completion"},
  {desc = "Confirm completion", answer = "<CR>", plugin = "completion"},
  {desc = "Next completion item", answer = "<C-n>", plugin = "completion"},
  {desc = "Previous completion item", answer = "<C-p>", plugin = "completion"},

  -- Comments
  {desc = "Toggle comment line", answer = "gcc", plugin = "comment", command_key = "toggle_comment"},
  {desc = "Toggle comment block", answer = "gbc", plugin = "comment"},
  {desc = "Comment selection (visual)", answer = "gc", plugin = "comment"},

  -- Misc
  {desc = "Save file", answer = "<leader>w", plugin = "general", command_key = "save_file"},
  {desc = "Quit", answer = "<leader>q", plugin = "general", command_key = "quit"},
  {desc = "Save all files", answer = "<leader>wa", plugin = "general"},
  {desc = "Close buffer", answer = "<leader>c", plugin = "general"},
  {desc = "Open lazy.nvim", answer = "<leader>l", plugin = "general"},
  {desc = "Open Mason", answer = "<leader>m", plugin = "general"},

  -- Additional common plugins
  -- Harpoon
  {desc = "Add file to Harpoon", answer = "<leader>a", plugin = "harpoon", command_key = "harpoon_add"},
  {desc = "Toggle Harpoon menu", answer = "<C-e>", plugin = "harpoon", command_key = "harpoon_menu"},
  {desc = "Jump to Harpoon file 1", answer = "<C-h>", plugin = "harpoon"},
  {desc = "Jump to Harpoon file 2", answer = "<C-t>", plugin = "harpoon"},

  -- Trouble
  {desc = "Toggle Trouble diagnostics", answer = "<leader>xx", plugin = "trouble", command_key = "toggle_trouble"},
  {desc = "Workspace diagnostics (Trouble)", answer = "<leader>xw", plugin = "trouble"},
  {desc = "Document diagnostics (Trouble)", answer = "<leader>xd", plugin = "trouble"},
  {desc = "Quickfix list (Trouble)", answer = "<leader>xq", plugin = "trouble"},

  -- Undotree
  {desc = "Toggle Undotree", answer = "<leader>u", plugin = "undotree", command_key = "toggle_undotree"},

  -- Zen mode / Focus
  {desc = "Toggle Zen mode", answer = "<leader>z", plugin = "zen", command_key = "toggle_zen"},

  -- Multiple cursors / visual multi
  {desc = "Add cursor down", answer = "<C-Down>", plugin = "multicursor"},
  {desc = "Add cursor up", answer = "<C-Up>", plugin = "multicursor"},

  -- Surround
  {desc = "Surround with parentheses", answer = "ysiw)", plugin = "surround"},
  {desc = "Change surrounding quotes", answer = "cs\"'", plugin = "surround"},
  {desc = "Delete surrounding parentheses", answer = "ds)", plugin = "surround"},

  -- LSP additional
  {desc = "Show diagnostics float", answer = "<leader>d", plugin = "lsp", command_key = "lsp_show_diagnostics"},
  {desc = "Go to next diagnostic", answer = "]d", plugin = "lsp", command_key = "lsp_next_diagnostic"},
  {desc = "Go to previous diagnostic", answer = "[d", plugin = "lsp", command_key = "lsp_prev_diagnostic"},
  {desc = "Open code actions", answer = "<leader>ca", plugin = "lsp", command_key = "lsp_code_action"},
  {desc = "Show type definition", answer = "<leader>D", plugin = "lsp", command_key = "lsp_type_definition"},

  -- Telescope additional
  {desc = "Git commits (Telescope)", answer = "<leader>gc", plugin = "telescope", command_key = "telescope_git_commits"},
  {desc = "Git branches (Telescope)", answer = "<leader>gb", plugin = "telescope", command_key = "telescope_git_branches"},
  {desc = "Symbols (Telescope)", answer = "<leader>fs", plugin = "telescope"},
  {desc = "Commands (Telescope)", answer = "<leader>fc", plugin = "telescope"},
  {desc = "Keymaps (Telescope)", answer = "<leader>fk", plugin = "telescope"},
  {desc = "Resume last search (Telescope)", answer = "<leader>fp", plugin = "telescope"},
}

function NvimCommandQuiz:new(player)
  local obj = BaseMode:new(player, 'nvim_command_quiz')
  setmetatable(obj, { __index = self })

  obj.questions_per_session = 15
  obj.current_question_idx = 1
  obj.question_list = {}
  obj.current_command = nil
  obj.typed_answer = ""
  obj.show_answer = false

  return obj
end

function NvimCommandQuiz:setup()
  -- Parse user's actual keymaps and override defaults
  local detected_count = 0
  local total_count = 0

  -- Shuffle commands using Fisher-Yates algorithm
  local shuffled = {}
  for i = 1, #self.COMMANDS do
    -- Clone the command and override answer with user's actual keymap if available
    local cmd = vim.deepcopy(self.COMMANDS[i])

    if cmd.command_key then
      total_count = total_count + 1
      local user_keymap = keymap_parser.get_keymap_for_command(cmd.command_key, cmd.answer)
      if user_keymap ~= cmd.answer then
        cmd.answer = user_keymap
        cmd.is_custom = true  -- Flag that this was detected from user config
        detected_count = detected_count + 1
      end
    end

    shuffled[i] = cmd
  end

  -- Notify user about detected keymaps
  if detected_count > 0 then
    vim.notify(string.format('✓ Detected %d/%d custom keymaps from your config!', detected_count, total_count), vim.log.levels.INFO)
  else
    vim.notify('Using default keybindings (no custom keymaps detected)', vim.log.levels.WARN)
  end

  for i = #shuffled, 2, -1 do
    local j = math.random(i)
    shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
  end

  -- Take first N commands
  for i = 1, math.min(self.questions_per_session, #shuffled) do
    table.insert(self.question_list, shuffled[i])
  end
end

function NvimCommandQuiz:generate_task()
  if self.current_question_idx > #self.question_list then
    self:exit()
    return
  end

  self.current_command = self.question_list[self.current_question_idx]
  self.typed_answer = ""
  self.show_answer = false
end

function NvimCommandQuiz:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function NvimCommandQuiz:setup_buffer_keymaps()
  BaseMode.setup_buffer_keymaps(self)

  vim.schedule(function()
    if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) then
      vim.cmd('startinsert')
    end
  end)

  local opts = { buffer = self.buffer, noremap = true, silent = true }

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
  vim.keymap.set('i', '<CR>', function() return self:submit() end, opts)
  vim.keymap.set('i', '<Tab>', function() return self:skip() end, opts)

  -- Map Ctrl combinations to insert their notation
  local ctrl_keys = 'abcdefghijklmnopqrstuvwxyz'
  for i = 1, #ctrl_keys do
    local letter = ctrl_keys:sub(i, i)
    vim.keymap.set('i', '<C-' .. letter .. '>', function()
      return self:handle_char('<C-' .. letter .. '>')
    end, opts)
  end

  -- Map Alt combinations
  for i = 1, #ctrl_keys do
    local letter = ctrl_keys:sub(i, i)
    vim.keymap.set('i', '<A-' .. letter .. '>', function()
      return self:handle_char('<A-' .. letter .. '>')
    end, opts)
  end

  -- Map F-keys
  for i = 1, 12 do
    vim.keymap.set('i', '<F' .. i .. '>', function()
      return self:handle_char('<F' .. i .. '>')
    end, opts)
  end
end

function NvimCommandQuiz:handle_char(char)
  self.typed_answer = self.typed_answer .. char
  self:render()
  return ''
end

function NvimCommandQuiz:backspace()
  if #self.typed_answer > 0 then
    self.typed_answer = self.typed_answer:sub(1, -2)
    self:render()
  end
  return ''
end

function NvimCommandQuiz:skip()
  if not self.show_answer then
    -- First press: show answer
    self.show_answer = true
    self:render()
  else
    -- Second press: move to next question
    self.current_question_idx = self.current_question_idx + 1
    self:generate_task()
    self:render()
  end
  return ''
end

function NvimCommandQuiz:submit()
  -- Check if answer matches (case-sensitive for keybindings)
  local correct = (self.typed_answer == self.current_command.answer)

  if correct then
    session.record_keystroke(self.session, true)
    session.increment_streak(self.session)
    vim.notify('✓ Correct!', vim.log.levels.INFO)

    local xp = self:calculate_xp()
    session.add_task_completion(self.session, xp)

    vim.defer_fn(function()
      if self.is_running then
        self.current_question_idx = self.current_question_idx + 1
        self:generate_task()
        self:render()
      end
    end, 800)
  else
    session.record_keystroke(self.session, false)
    session.break_streak(self.session)
    vim.notify('✗ Wrong! Correct answer: ' .. self.current_command.answer, vim.log.levels.WARN)

    vim.defer_fn(function()
      if self.is_running then
        self.show_answer = true
        self.typed_answer = ""
        self:render()
      end
    end, 1500)
  end

  return ''
end

function NvimCommandQuiz:update(key)
  return false
end

function NvimCommandQuiz:render()
  local lines = {}

  table.insert(lines, '')
  table.insert(lines, '═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '                     🔧 NEOVIM COMMAND QUIZ')
  table.insert(lines, '═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '')
  table.insert(lines, '                     💡 SPACE = <leader>')
  table.insert(lines, '                     (Type: <leader>ff for leader+f+f)')
  table.insert(lines, '')
  table.insert(lines, string.format('                     Question %d of %d',
    self.current_question_idx, self.questions_per_session))
  table.insert(lines, '')
  table.insert(lines, '───────────────────────────────────────────────────────────────────')
  table.insert(lines, '')

  if self.current_command then
    table.insert(lines, '  COMMAND:')
    table.insert(lines, '  ' .. self.current_command.desc)
    local plugin_line = '  [' .. self.current_command.plugin .. ']'
    if self.current_command.is_custom then
      plugin_line = plugin_line .. ' 🔍 Detected from your config'
    end
    table.insert(lines, plugin_line)
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '  YOUR KEYBINDING:')
    table.insert(lines, '  > ' .. self.typed_answer .. '_')
    table.insert(lines, '')

    if self.show_answer then
      table.insert(lines, '')
      table.insert(lines, '  ✓ CORRECT ANSWER: ' .. self.current_command.answer)
      if self.current_command.is_custom then
        table.insert(lines, '    (From your Neovim config)')
      end
      table.insert(lines, '')
    end
  end

  table.insert(lines, '')
  table.insert(lines, '───────────────────────────────────────────────────────────────────')
  table.insert(lines, string.format('  Accuracy: %.1f%%  |  Streak: %d  |  XP: %d',
    session.calculate_accuracy(self.session), self.session.current_streak, self.session.xp_earned))
  table.insert(lines, '───────────────────────────────────────────────────────────────────')

  -- Add consistent controls legend
  local controls = self:render_controls_legend({
    {key = 'Type', desc = 'Type keybinding literally (e.g., <leader>ff or <C-u>)'},
    {key = 'ENTER', desc = 'Submit answer'},
    {key = 'TAB', desc = 'Show answer / Next question'},
    {key = 'ESC', desc = 'Exit to menu'},
    {key = 'Note', desc = 'Quiz uses YOUR actual keymaps (auto-detected from config)'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)
end

function NvimCommandQuiz:calculate_xp()
  local base_xp = 20
  local accuracy = session.calculate_accuracy(self.session)

  return xp_module.calculate(base_xp, {
    accuracy = accuracy,
    streak = self.session.current_streak,
  })
end

return NvimCommandQuiz
