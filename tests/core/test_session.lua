local helper = require('tests.test_helper')
helper.setup()

local session_mod = require('typing_kata.core.session')

print("Running Session Tests...")

-- Test 1: New Session
local s = session_mod.new("test_mode")
helper.assert_eq("test_mode", s.mode_name, "Mode name matches")
helper.assert_eq(0, s.tasks_completed, "Tasks starts at 0")
helper.assert_eq(0, s.current_streak, "Streak starts at 0")

-- Test 2: Record Keystroke
session_mod.record_keystroke(s, true)
helper.assert_eq(1, s.total_keystrokes, "Total keystrokes increments")
helper.assert_eq(1, s.correct_keystrokes, "Correct keystrokes increments")
helper.assert_eq(0, s.error_count, "Error count stays 0")

session_mod.record_keystroke(s, false)
helper.assert_eq(2, s.total_keystrokes, "Total keystrokes increments")
helper.assert_eq(1, s.correct_keystrokes, "Correct keystrokes stays same")
helper.assert_eq(1, s.error_count, "Error count increments")

-- Test 3: Accuracy
local acc = session_mod.calculate_accuracy(s)
helper.assert_eq(50.0, acc, "Accuracy should be 50%")

-- Test 4: Streak Logic
session_mod.break_streak(s)
helper.assert_eq(0, s.current_streak, "Streak broken")

session_mod.increment_streak(s)
helper.assert_eq(1, s.current_streak, "Streak incremented")
helper.assert_eq(1, s.best_streak, "Best streak updated")

session_mod.break_streak(s)
helper.assert_eq(0, s.current_streak, "Streak broken again")
helper.assert_eq(1, s.best_streak, "Best streak preserved")

print("✅ Session Tests Passed!")
