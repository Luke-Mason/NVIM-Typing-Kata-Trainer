-- Parse user's actual Neovim keymaps to personalize quiz answers
local M = {}

-- Extract keymaps from Neovim runtime
function M.get_user_keymaps()
  local keymaps = {
    normal = {},
    visual = {},
    insert = {},
  }

  -- Get keymaps for each mode
  local modes = {'n', 'v', 'i'}

  for _, mode in ipairs(modes) do
    local mode_maps = vim.api.nvim_get_keymap(mode)
    local mode_name = mode == 'n' and 'normal' or mode == 'v' and 'visual' or 'insert'

    for _, map in ipairs(mode_maps) do
      local lhs = map.lhs or ''
      local rhs = map.rhs or ''
      local desc = map.desc or ''

      -- Store the mapping
      keymaps[mode_name][lhs] = {
        rhs = rhs,
        desc = desc,
        callback = map.callback,
      }
    end
  end

  return keymaps
end

-- Build a reverse lookup: command/action -> keybinding
function M.build_command_to_keymap_lookup()
  local lookup = {}
  local keymaps = M.get_user_keymaps()

  -- Pattern matching for common commands
  local patterns = {
    -- Telescope
    {pattern = "telescope.*find_files", key = "telescope_find_files"},
    {pattern = "telescope.*live_grep", key = "telescope_live_grep"},
    {pattern = "telescope.*buffers", key = "telescope_buffers"},
    {pattern = "telescope.*help_tags", key = "telescope_help_tags"},
    {pattern = "telescope.*oldfiles", key = "telescope_recent_files"},
    {pattern = "telescope.*git_commits", key = "telescope_git_commits"},
    {pattern = "telescope.*git_branches", key = "telescope_git_branches"},

    -- LSP
    {pattern = "vim%.lsp%.buf%.definition", key = "lsp_goto_definition"},
    {pattern = "vim%.lsp%.buf%.declaration", key = "lsp_goto_declaration"},
    {pattern = "vim%.lsp%.buf%.hover", key = "lsp_hover"},
    {pattern = "vim%.lsp%.buf%.implementation", key = "lsp_goto_implementation"},
    {pattern = "vim%.lsp%.buf%.signature_help", key = "lsp_signature_help"},
    {pattern = "vim%.lsp%.buf%.rename", key = "lsp_rename"},
    {pattern = "vim%.lsp%.buf%.code_action", key = "lsp_code_action"},
    {pattern = "vim%.lsp%.buf%.references", key = "lsp_references"},
    {pattern = "vim%.lsp%.buf%.format", key = "lsp_format"},
    {pattern = "vim%.diagnostic%.open_float", key = "lsp_show_diagnostics"},
    {pattern = "vim%.diagnostic%.goto_next", key = "lsp_next_diagnostic"},
    {pattern = "vim%.diagnostic%.goto_prev", key = "lsp_prev_diagnostic"},
    {pattern = "vim%.lsp%.buf%.type_definition", key = "lsp_type_definition"},

    -- Git
    {pattern = "gitsigns.*stage_hunk", key = "git_stage_hunk"},
    {pattern = "gitsigns.*reset_hunk", key = "git_reset_hunk"},
    {pattern = "gitsigns.*next_hunk", key = "git_next_hunk"},
    {pattern = "gitsigns.*prev_hunk", key = "git_prev_hunk"},
    {pattern = "gitsigns.*blame_line", key = "git_blame_line"},
    {pattern = "fugitive", key = "git_status"},

    -- File tree
    {pattern = "NvimTreeToggle", key = "toggle_file_tree"},
    {pattern = "NvimTreeFindFile", key = "find_file_in_tree"},
    {pattern = "NeoTreeReveal", key = "toggle_file_tree"},
    {pattern = "NeoTreeFocus", key = "toggle_file_tree"},

    -- Terminal
    {pattern = "ToggleTerm", key = "toggle_terminal"},
    {pattern = "TermExec", key = "terminal_exec"},

    -- Trouble
    {pattern = "Trouble", key = "toggle_trouble"},
    {pattern = "TroubleToggle", key = "toggle_trouble"},

    -- Harpoon
    {pattern = "harpoon.*add_file", key = "harpoon_add"},
    {pattern = "harpoon.*toggle_quick_menu", key = "harpoon_menu"},

    -- Comment
    {pattern = "comment%.api", key = "toggle_comment"},

    -- DAP (debugging)
    {pattern = "dap%.continue", key = "dap_continue"},
    {pattern = "dap%.step_over", key = "dap_step_over"},
    {pattern = "dap%.step_into", key = "dap_step_into"},
    {pattern = "dap%.step_out", key = "dap_step_out"},
    {pattern = "dap%.toggle_breakpoint", key = "dap_toggle_breakpoint"},

    -- Navigation
    {pattern = "bnext", key = "next_buffer"},
    {pattern = "bprevious", key = "prev_buffer"},
    {pattern = "bd", key = "close_buffer"},

    -- Zen mode
    {pattern = "ZenMode", key = "toggle_zen"},

    -- Undotree
    {pattern = "UndotreeToggle", key = "toggle_undotree"},

    -- General
    {pattern = "^:w<", key = "save_file"},
    {pattern = "^:wq<", key = "save_quit"},
    {pattern = "^:q<", key = "quit"},
  }

  -- Search through all keymaps
  for mode_name, mode_maps in pairs(keymaps) do
    for lhs, map_data in pairs(mode_maps) do
      local rhs = map_data.rhs or ''
      local desc = (map_data.desc or ''):lower()

      -- Try to match against patterns
      for _, pattern_entry in ipairs(patterns) do
        if rhs:match(pattern_entry.pattern) or desc:match(pattern_entry.pattern:gsub("%%", "")) then
          lookup[pattern_entry.key] = {
            keymap = lhs,
            mode = mode_name,
            desc = map_data.desc,
          }
          break
        end
      end
    end
  end

  return lookup
end

-- Get the user's keybinding for a specific command, or return default
function M.get_keymap_for_command(command_key, default_answer)
  -- Cache the lookup table
  if not M._cached_lookup then
    M._cached_lookup = M.build_command_to_keymap_lookup()
  end

  local user_keymap = M._cached_lookup[command_key]

  if user_keymap and user_keymap.keymap then
    return user_keymap.keymap
  end

  return default_answer
end

-- Clear cache (useful if keymaps change)
function M.clear_cache()
  M._cached_lookup = nil
end

return M
