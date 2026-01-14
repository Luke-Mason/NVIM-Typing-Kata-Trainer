local M = {}

M.motions = {
  -- Basic motions
  {keys = "h", desc = "Move left"},
  {keys = "j", desc = "Move down"},
  {keys = "k", desc = "Move up"},
  {keys = "l", desc = "Move right"},
  {keys = "w", desc = "Move to start of next word"},
  {keys = "b", desc = "Move to start of previous word"},
  {keys = "e", desc = "Move to end of word"},
  {keys = "0", desc = "Move to start of line"},
  {keys = "$", desc = "Move to end of line"},

  -- Word motions with counts
  {keys = "5w", desc = "Move 5 words forward"},
  {keys = "3b", desc = "Move 3 words back"},
  {keys = "10j", desc = "Move 10 lines down"},
  {keys = "7k", desc = "Move 7 lines up"},

  -- Search motions
  {keys = "f", desc = "Find character forward in line (followed by char)"},
  {keys = "t", desc = "Till character forward (before char)"},
  {keys = "F", desc = "Find character backward in line"},
  {keys = "T", desc = "Till character backward"},

  -- Text objects and operators
  {keys = "d", desc = "Delete operator"},
  {keys = "c", desc = "Change operator"},
  {keys = "y", desc = "Yank (copy) operator"},
  {keys = "v", desc = "Visual mode"},
  {keys = "V", desc = "Visual line mode"},

  -- Combined operations
  {keys = "dw", desc = "Delete word"},
  {keys = "d3w", desc = "Delete 3 words"},
  {keys = "ciw", desc = "Change inner word"},
  {keys = "di(", desc = "Delete inside parentheses"},
  {keys = "yi\"", desc = "Yank inside double quotes"},
  {keys = "va{", desc = "Visual select around braces"},
  {keys = "dt;", desc = "Delete till semicolon"},

  -- Control combinations
  {keys = "<C-d>", desc = "Scroll down half page"},
  {keys = "<C-u>", desc = "Scroll up half page"},
  {keys = "<C-f>", desc = "Scroll down full page"},
  {keys = "<C-b>", desc = "Scroll up full page"},
  {keys = "<C-o>", desc = "Jump to previous location"},
  {keys = "<C-i>", desc = "Jump to next location"},
  {keys = "<C-r>", desc = "Redo"},
  {keys = "<C-w>v", desc = "Split window vertically"},
  {keys = "<C-w>s", desc = "Split window horizontally"},
  {keys = "<C-w>h", desc = "Move to left window"},
  {keys = "<C-w>j", desc = "Move to bottom window"},
  {keys = "<C-w>k", desc = "Move to top window"},
  {keys = "<C-w>l", desc = "Move to right window"},

  -- Insert mode combinations
  {keys = "<C-n>", desc = "Autocomplete next"},
  {keys = "<C-p>", desc = "Autocomplete previous"},
  {keys = "<C-x><C-o>", desc = "Omni completion"},
  {keys = "<C-x><C-f>", desc = "File path completion"},

  -- Command combinations
  {keys = "gg", desc = "Go to first line"},
  {keys = "G", desc = "Go to last line"},
  {keys = "50G", desc = "Go to line 50"},
  {keys = "u", desc = "Undo"},
  {keys = ".", desc = "Repeat last change"},
  {keys = ">>", desc = "Indent line"},
  {keys = "<<", desc = "Unindent line"},
  {keys = "==", desc = "Auto-indent line"},

  -- Marks and jumps
  {keys = "ma", desc = "Set mark 'a'"},
  {keys = "'a", desc = "Jump to mark 'a'"},
  {keys = "``", desc = "Jump to last position"},

  -- Macros
  {keys = "qa", desc = "Record macro to register 'a'"},
  {keys = "q", desc = "Stop recording macro"},
  {keys = "@a", desc = "Play macro from register 'a'"},
  {keys = "@@", desc = "Repeat last macro"},
}

return M
