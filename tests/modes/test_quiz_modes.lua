local helper = require('tests.test_helper')
helper.setup()

local BaseQuizMode = require('typing_kata.modes.base_quiz_mode')
local NvimCommandQuiz = require('typing_kata.modes.nvim_command_quiz')
local VimMotionsQuiz = require('typing_kata.modes.vim_motions_quiz')

print("Testing Quiz Modes...")

-- Mock Player
local player = { current_xp = 0, stats = {} }

-- Test 1: Vim Motions Quiz Data
local motions_quiz = VimMotionsQuiz:new(player)
local questions = motions_quiz:get_questions()
helper.assert_true(#questions > 0, "Should have motions questions")
helper.assert_true(questions[1].task ~= nil, "Question should have task")
helper.assert_true(questions[1].answer ~= nil, "Question should have answer")

-- Test 2: Check Answer Logic
local q1 = { answer = "daw" }
helper.assert_true(motions_quiz:check_answer("daw", q1), "Should match correct answer")
helper.assert_true(not motions_quiz:check_answer("daw ", q1), "Should fail with extra space")

local q2 = { answer = "d3j", alt_answers = {"3dd"} }
helper.assert_true(motions_quiz:check_answer("3dd", q2), "Should match alt answer")

-- Test 3: Nvim Command Quiz Data
local cmd_quiz = NvimCommandQuiz:new(player)
-- This might be empty if we have no keymaps? 
-- Actually it loads from nvim_commands.lua first, then checks keymaps.
-- So it should have data.
local cmd_questions = cmd_quiz:get_questions()
helper.assert_true(#cmd_questions > 0, "Should have command questions")

print("✅ Quiz Modes Valid")
