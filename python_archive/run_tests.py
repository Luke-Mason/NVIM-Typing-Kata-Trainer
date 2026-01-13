"""Test runner script for NVIM Typing Kata Trainer.

This script runs different test suites:
- Unit tests: Fast tests of individual components
- Integration tests: Tests of game mode gameplay
- System tests: End-to-end tests of the full application
"""
import sys
import subprocess
from pathlib import Path


def run_command(cmd, description):
    """Run a command and print results."""
    print(f"\n{'=' * 70}")
    print(f"  {description}")
    print(f"{'=' * 70}\n")

    result = subprocess.run(cmd, shell=True)
    return result.returncode == 0


def main():
    """Run test suites."""
    if len(sys.argv) > 1:
        test_type = sys.argv[1].lower()
    else:
        test_type = "all"

    success = True

    if test_type in ["all", "unit"]:
        # Run unit tests (fast)
        success &= run_command(
            "pytest tests/ -v -m 'not slow' --ignore=tests/test_gameplay_integration.py --ignore=tests/test_system_e2e.py",
            "Running Unit Tests (Fast)"
        )

    if test_type in ["all", "integration"]:
        # Run integration tests (gameplay simulation)
        success &= run_command(
            "pytest tests/test_gameplay_integration.py -v",
            "Running Integration Tests (Gameplay Simulation)"
        )

    if test_type in ["all", "system", "e2e"]:
        # Run system/e2e tests (full app)
        success &= run_command(
            "pytest tests/test_system_e2e.py -v",
            "Running System Tests (End-to-End with Full App)"
        )

    if test_type == "quick":
        # Quick smoke test
        success &= run_command(
            "pytest tests/test_system_e2e.py::TestApplicationStartup -v",
            "Running Quick Smoke Test"
        )

    if test_type == "all":
        # Run all tests with coverage
        print(f"\n{'=' * 70}")
        print("  Summary - Running All Tests with Coverage")
        print(f"{'=' * 70}\n")
        success &= run_command(
            "pytest tests/ -v --cov=src --cov-report=term-missing",
            "All Tests with Coverage"
        )

    print(f"\n{'=' * 70}")
    if success:
        print("  ✓ All tests passed!")
    else:
        print("  ✗ Some tests failed!")
    print(f"{'=' * 70}\n")

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
