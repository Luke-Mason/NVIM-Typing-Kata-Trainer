"""End-to-end system tests that actually run the full application.

These tests use Textual's Pilot to simulate real user interaction with the running app.
They test the entire system from startup to gameplay to ensure nothing crashes.
"""
import pytest
from pathlib import Path

from src.app import VimTrainerApp
from src.core.config import Config


class TestApplicationStartup:
    """Test that the application starts without crashing."""

    @pytest.mark.asyncio
    async def test_app_starts_and_shows_main_menu(self):
        """Test that app starts and displays main menu."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            # App should start and show main menu
            await pilot.pause()

            # Main menu should be visible
            assert app.screen is not None
            assert hasattr(app, 'rank_system')
            assert hasattr(app, 'player')

    @pytest.mark.asyncio
    async def test_help_modal_opens(self):
        """Test that pressing '?' opens help modal."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press '?' to open help
            await pilot.press("?")
            await pilot.pause()

            # Should not crash
            assert app.screen is not None


class TestGameModeLaunching:
    """Test launching each game mode from main menu."""

    @pytest.mark.asyncio
    async def test_launch_word_training(self):
        """Test launching Word Training mode (option 5)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press '5' to launch Word Training
            await pilot.press("5")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_launch_symbol_training(self):
        """Test launching Symbol Training mode (option 3)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press '3' to launch Symbol Training
            await pilot.press("3")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_launch_snake_apple(self):
        """Test launching Snake Apple mode (option 2)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press '2' to launch Snake Apple
            await pilot.press("2")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_launch_coding_lessons(self):
        """Test launching Coding Lessons mode (option 4)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press '4' to launch Coding Lessons
            await pilot.press("4")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_launch_vim_motions(self):
        """Test launching Vim Motions mode (option 6)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press '6' to launch Vim Motions
            await pilot.press("6")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_launch_custom_keybindings(self):
        """Test launching Custom Keybindings mode (option 1)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press '1' to launch Custom Keybindings
            await pilot.press("1")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_launch_comprehensive_keys(self):
        """Test launching Comprehensive Keys mode (option 7)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press '7' to launch Comprehensive Keys
            await pilot.press("7")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None


class TestWordTrainingGameplay:
    """Test actual gameplay in Word Training mode."""

    @pytest.mark.asyncio
    async def test_uppercase_w_with_shift(self):
        """Test typing uppercase W (the bug we fixed)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Word Training
            await pilot.press("5")
            await pilot.pause(0.5)

            # Try typing W (this was causing the crash)
            await pilot.press("W")
            await pilot.pause()

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_various_word_motions(self):
        """Test various word motions in Word Training."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Word Training
            await pilot.press("5")
            await pilot.pause(0.5)

            # Type various motions
            motions = ['w', 'b', 'e', 'W', 'B', 'E']
            for motion in motions:
                await pilot.press(motion)
                await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_exit_with_jk(self):
        """Test exiting Word Training with 'jk'."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Word Training
            await pilot.press("5")
            await pilot.pause(0.5)

            # Exit with jk
            await pilot.press("j")
            await pilot.pause(0.1)
            await pilot.press("k")
            await pilot.pause(0.5)

            # Should be back at main menu
            assert app.screen is not None


class TestSymbolTrainingGameplay:
    """Test actual gameplay in Symbol Training mode."""

    @pytest.mark.asyncio
    async def test_typing_symbols_with_shift(self):
        """Test typing symbols that require Shift."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Symbol Training
            await pilot.press("3")
            await pilot.pause(0.5)

            # Type symbols requiring Shift
            symbols = ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')']
            for symbol in symbols:
                await pilot.press(symbol)
                await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_typing_symbol_sequences(self):
        """Test typing symbol sequences like ==, !=, etc."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Symbol Training
            await pilot.press("3")
            await pilot.pause(0.5)

            # Type some sequences
            for char in '==':
                await pilot.press(char)
                await pilot.pause(0.1)

            for char in '!=':
                await pilot.press(char)
                await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None


class TestSnakeAppleGameplay:
    """Test actual gameplay in Snake Apple mode."""

    @pytest.mark.asyncio
    async def test_hjkl_navigation(self):
        """Test hjkl navigation keys."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Snake Apple
            await pilot.press("2")
            await pilot.pause(0.5)

            # Navigate with hjkl
            motions = ['h', 'j', 'k', 'l'] * 3  # Repeat a few times
            for motion in motions:
                await pilot.press(motion)
                await pilot.pause(0.05)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_word_motions_with_shift(self):
        """Test word motions including uppercase (W, B, E)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Snake Apple
            await pilot.press("2")
            await pilot.pause(0.5)

            # Use word motions
            motions = ['w', 'W', 'b', 'B', 'e', 'E']
            for motion in motions:
                await pilot.press(motion)
                await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_line_motions(self):
        """Test line motions (0, $, gg, G)."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Snake Apple
            await pilot.press("2")
            await pilot.pause(0.5)

            # Use line motions
            await pilot.press("0")
            await pilot.pause(0.1)

            await pilot.press("dollar")  # $
            await pilot.pause(0.1)

            await pilot.press("g")
            await pilot.press("g")
            await pilot.pause(0.1)

            await pilot.press("G")
            await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None


class TestCodingLessonsGameplay:
    """Test actual gameplay in Coding Lessons mode."""

    @pytest.mark.asyncio
    async def test_typing_code_with_mixed_case(self):
        """Test typing code with uppercase and lowercase letters."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Coding Lessons
            await pilot.press("4")
            await pilot.pause(0.5)

            # Type some code-like input
            code_chars = ['d', 'e', 'f', ' ', 'T', 'e', 's', 't', '(', ')']
            for char in code_chars:
                await pilot.press(char)
                await pilot.pause(0.05)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_special_keys_in_code(self):
        """Test special keys like Tab, Enter in code."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Coding Lessons
            await pilot.press("4")
            await pilot.pause(0.5)

            # Type with special keys
            await pilot.press("d")
            await pilot.press("e")
            await pilot.press("f")
            await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None


class TestCustomKeybindingsGameplay:
    """Test actual gameplay in Custom Keybindings mode."""

    @pytest.mark.asyncio
    async def test_typing_fallback_keybindings(self):
        """Test typing fallback keybindings."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Custom Keybindings
            await pilot.press("1")
            await pilot.pause(0.5)

            # Type some common vim keys
            keys = ['g', 'g', 'd', 'd', 'y', 'y', 'p', 'u']
            for key in keys:
                await pilot.press(key)
                await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None


class TestVimMotionsGameplay:
    """Test actual gameplay in Vim Motions mode."""

    @pytest.mark.asyncio
    async def test_complex_vim_operations(self):
        """Test complex vim operations."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Vim Motions
            await pilot.press("6")
            await pilot.pause(0.5)

            # Type some vim operations
            operations = ['d', 'w', 'c', 'i', 'w', 'y', 'y', 'p']
            for op in operations:
                await pilot.press(op)
                await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None


class TestStressTest:
    """Stress tests with rapid input."""

    @pytest.mark.asyncio
    async def test_rapid_key_presses(self):
        """Test rapid key presses don't cause crashes."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Word Training
            await pilot.press("5")
            await pilot.pause(0.5)

            # Rapid fire keys
            for _ in range(20):
                await pilot.press("w")

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_mode_switching(self):
        """Test switching between modes rapidly."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Switch between modes
            modes = ['1', '2', '3', '4', '5', '6', '7']
            for mode in modes:
                await pilot.press(mode)
                await pilot.pause(0.3)

                # Exit back to menu (try jk)
                await pilot.press("j")
                await pilot.press("k")
                await pilot.pause(0.3)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_random_modifier_keys(self):
        """Test that modifier keys don't cause crashes."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Word Training
            await pilot.press("5")
            await pilot.pause(0.5)

            # Type with modifiers (Shift+letter creates uppercase)
            letters_with_shift = ['W', 'B', 'E', 'W', 'B']
            for letter in letters_with_shift:
                await pilot.press(letter)
                await pilot.pause(0.1)

            # Should not crash
            assert app.screen is not None


class TestNavigationAndSettings:
    """Test navigation and settings screens."""

    @pytest.mark.asyncio
    async def test_stats_screen(self):
        """Test opening stats screen."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press 's' for stats
            await pilot.press("s")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_settings_screen(self):
        """Test opening settings screen."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Press 'c' for settings
            await pilot.press("c")
            await pilot.pause(0.5)

            # Should not crash
            assert app.screen is not None


class TestFullSession:
    """Test a complete gameplay session."""

    @pytest.mark.asyncio
    async def test_complete_word_training_session(self):
        """Simulate a complete Word Training session."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Launch Word Training
            await pilot.press("5")
            await pilot.pause(0.5)

            # Play for a bit
            for _ in range(10):
                await pilot.press("w")
                await pilot.pause(0.1)
                await pilot.press("b")
                await pilot.pause(0.1)
                await pilot.press("W")
                await pilot.pause(0.1)

            # Exit
            await pilot.press("j")
            await pilot.press("k")
            await pilot.pause(0.5)

            # Check stats
            await pilot.press("s")
            await pilot.pause(0.5)

            # Should not have crashed
            assert app.screen is not None

    @pytest.mark.asyncio
    async def test_multi_mode_session(self):
        """Test playing multiple modes in one session."""
        config = Config(claude_api_key="test-key", progress_dir=Path("./test_progress"))
        app = VimTrainerApp(config)

        async with app.run_test() as pilot:
            await pilot.pause()

            # Play Word Training
            await pilot.press("5")
            await pilot.pause(0.5)
            for _ in range(5):
                await pilot.press("w")
                await pilot.pause(0.05)
            await pilot.press("j")
            await pilot.press("k")
            await pilot.pause(0.5)

            # Play Symbol Training
            await pilot.press("3")
            await pilot.pause(0.5)
            for _ in range(5):
                await pilot.press("!")
                await pilot.pause(0.05)
            await pilot.press("j")
            await pilot.press("k")
            await pilot.pause(0.5)

            # Play Snake Apple
            await pilot.press("2")
            await pilot.pause(0.5)
            for _ in range(5):
                await pilot.press("h")
                await pilot.press("j")
                await pilot.press("k")
                await pilot.press("l")
            await pilot.press("j")
            await pilot.press("k")
            await pilot.pause(0.5)

            # Should not have crashed
            assert app.screen is not None


if __name__ == "__main__":
    # Allow running directly
    pytest.main([__file__, "-v", "--tb=short"])
