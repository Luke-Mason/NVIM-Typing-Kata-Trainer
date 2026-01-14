local M = {}

function M.run()
  local log_file = io.open("system_test.log", "w")
  local function log(msg)
    log_file:write(msg .. "\n")
    print(msg)
  end

  log("🚀 Starting System Tests...")
  
  -- Setup environment
  vim.opt.swapfile = false
  package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'
  
  -- Mock random seed for deterministic behavior
  math.randomseed(12345)
  
  require('typing_kata').setup({
    data_dir = "./tests/temp_data" -- Use temp dir for tests
  })
  
  -- 1. Start Mode
  log("  Starting Symbol Training...")
  local SymbolTraining = require('typing_kata.modes.symbol_training')
  local player = require('typing_kata.core.player').new_player("TestUser")
  local mode = SymbolTraining:new(player)
  
  mode:start()
  
  local buf = mode.buffer
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    log("  ❌ Error: Buffer not created!")
    os.exit(1)
  end
  
  -- 2. Verify Initial State
  -- Modifiable check (The Bug!)
  local modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')
  if not modifiable then
    log("  ❌ CRITICAL BUG REPRODUCED: Buffer is not modifiable on start!")
    log("  User cannot recover if they exit Insert mode.")
    log_file:close()
    os.exit(1) -- Fail
  else
    log("  ✓ Buffer is modifiable")
  end
  
  log("✅ All System Tests Passed!")
  log_file:close()
  vim.cmd('qall!')
end

-- Execute!
M.run()

return M
