local helper = require('tests.test_helper')
helper.setup()

local samples = require('typing_kata.core.code_samples')

print("Testing Code Samples...")

helper.assert_true(#samples.samples > 0, "Should have samples")

local first = samples.samples[1]
helper.assert_true(first.code ~= nil, "Sample should have code")
helper.assert_true(first.filetype ~= nil, "Sample should have filetype")

print("✅ Code Samples Valid")
