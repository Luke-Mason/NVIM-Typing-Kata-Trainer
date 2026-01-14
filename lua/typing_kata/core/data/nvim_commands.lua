local M = {}

M.commands = {
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

return M
