-- Test helper to setup environment
local M = {}

function M.setup()
  -- Add project lua directory to package path
  -- Assumes we are running from project root
  package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'
end

-- Simple assertion functions
function M.assert_eq(expected, actual, message)
  if expected ~= actual then
    error(string.format("Assertion failed: %s\nExpected: %s\nActual:   %s", 
      message or "Values not equal", tostring(expected), tostring(actual)))
  end
end

function M.assert_true(condition, message)
  if not condition then
    error(string.format("Assertion failed: %s", message or "Condition not true"))
  end
end

return M
