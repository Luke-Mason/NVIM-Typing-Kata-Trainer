-- Quick syntax check for all Lua files
local function check_file(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    print('❌ Cannot open: ' .. filepath)
    return false
  end

  local content = file:read('*a')
  file:close()

  local func, err = load(content, filepath)
  if not func then
    print('❌ Syntax error in ' .. filepath)
    print('   ' .. err)
    return false
  end

  print('✓ ' .. filepath)
  return true
end

local files = {
  'lua/typing_kata/init.lua',
  'lua/typing_kata/config.lua',
  'lua/typing_kata/core/player.lua',
  'lua/typing_kata/core/ranks.lua',
  'lua/typing_kata/core/session.lua',
  'lua/typing_kata/core/xp.lua',
  'lua/typing_kata/ui/buffer.lua',
  'lua/typing_kata/ui/highlights.lua',
  'lua/typing_kata/ui/menu.lua',
  'lua/typing_kata/ui/stats.lua',
  'lua/typing_kata/modes/base_mode.lua',
  'lua/typing_kata/modes/symbol_training.lua',
  'lua/typing_kata/modes/word_typing.lua',
  'lua/typing_kata/modes/snake_apple.lua',
}

print('Checking Lua syntax...\n')
local all_ok = true
for _, file in ipairs(files) do
  if not check_file(file) then
    all_ok = false
  end
end

if all_ok then
  print('\n✅ All files passed syntax check!')
else
  print('\n❌ Some files have syntax errors')
  os.exit(1)
end
