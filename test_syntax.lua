-- Syntax test script
local function test_syntax(filepath)
  local f = loadfile(filepath)
  if f then
    print("✓ " .. filepath .. " - syntax OK")
    return true
  else
    print("✗ " .. filepath .. " - syntax ERROR")
    return false
  end
end

local files = {
  "lua/typing_kata/ui/typing_display.lua",
  "lua/typing_kata/ui/highlights.lua",
  "lua/typing_kata/modes/symbol_training.lua",
  "lua/typing_kata/modes/word_typing.lua",
}

local all_ok = true
for _, file in ipairs(files) do
  if not test_syntax(file) then
    all_ok = false
  end
end

if all_ok then
  print("\nAll files passed syntax check!")
else
  print("\nSome files have syntax errors!")
  os.exit(1)
end
