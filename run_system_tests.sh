#!/bin/bash
echo "Running System Integration Tests..."
nvim --headless -l scripts/run_system_tests.lua
if [ $? -eq 0 ]; then
  echo "Tests passed."
else
  echo "Tests failed."
  exit 1
fi
