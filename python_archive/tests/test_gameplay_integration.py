"""Integration tests that simulate actual gameplay for all game modes.

These tests simulate real user input to catch runtime errors before users encounter them.
"""
import pytest
import asyncio
from unittest.mock import Mock
from pathlib import Path

from src.core.config import Config
from src.models.player import Player
from src.input.keyboard_handler import KeyEvent
from src.game_modes.word_training import WordTrainingMode
from src.game_modes.vim_motions import VimMotionsMode
from src.game_modes.custom_keybindings import CustomKeybindingsMode
from src.game_modes.coding_lessons import CodingLessonsMode
from src.game_modes.snake_apple import SnakeAppleMode
from src.game_modes.symbol_training import SymbolTrainingMode
from src.game_modes.comprehensive_keys import ComprehensiveKeysMode


def create_key_event(char=None, key_name=None, modifiers=None):
    """Create a mock KeyEvent for testing."""
    return KeyEvent(
        key=None,
        char=char,
        modifiers=modifiers or set(),
        key_name=key_name or (char if char else 'unknown')
    )


def create_test_config():
    """Create a test configuration."""
    return Config(
        claude_api_key="test-key",
        nvim_config_dir=None,
        vimrc_path=None,
        progress_dir=Path("./test_progress"),
        universal_exit_sequence="jk"
    )


def create_test_player():
    """Create a test player."""
    return Player(name="TestPlayer")


class TestWordTrainingGameplay:
    """Test Word Training mode gameplay."""

    @pytest.mark.asyncio
    async def test_basic_word_motions(self):
        """Test basic word motion inputs don't crash."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTrainingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Test basic word motions
        motions = ['w', 'b', 'e']
        for motion in motions:
            event = create_key_event(char=motion)
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Word motion '{motion}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_uppercase_word_motions(self):
        """Test uppercase word motions (with Shift) don't crash."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTrainingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Test uppercase motions (simulating Shift+key)
        uppercase_motions = ['W', 'B', 'E']
        for motion in uppercase_motions:
            # First send Shift key (should be ignored)
            shift_event = create_key_event(key_name='Shift', modifiers={'shift'})
            await mode.update(shift_event)

            # Then send the uppercase letter
            event = create_key_event(char=motion, modifiers={'shift'})
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Uppercase motion '{motion}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_invalid_input(self):
        """Test invalid inputs are handled gracefully."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTrainingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Test invalid keys
        invalid_keys = ['x', 'z', '1', '!']
        for key in invalid_keys:
            event = create_key_event(char=key)
            try:
                result = await mode.update(event)
                assert result is False  # Invalid input should return False
            except Exception as e:
                pytest.fail(f"Invalid key '{key}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_display_text_generation(self):
        """Test display text can be generated without errors."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTrainingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        try:
            display = mode.get_display_text()
            assert isinstance(display, str)
            assert len(display) > 0
        except Exception as e:
            pytest.fail(f"get_display_text() caused error: {e}")


class TestSymbolTrainingGameplay:
    """Test Symbol Training mode gameplay."""

    @pytest.mark.asyncio
    async def test_single_symbols(self):
        """Test typing single symbols doesn't crash."""
        config = create_test_config()
        player = create_test_player()
        mode = SymbolTrainingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Test various symbols (some require Shift)
        symbols = ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '=']
        for symbol in symbols:
            # Regenerate task
            await mode.generate_task()

            # Send Shift if needed (for symbols requiring Shift)
            if symbol in '!@#$%^&*()':
                shift_event = create_key_event(key_name='Shift', modifiers={'shift'})
                await mode.update(shift_event)

            event = create_key_event(char=symbol, modifiers={'shift'} if symbol in '!@#$%^&*()' else set())
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Symbol '{symbol}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_symbol_sequences(self):
        """Test typing symbol sequences doesn't crash."""
        config = create_test_config()
        player = create_test_player()
        mode = SymbolTrainingMode(config, player)

        await mode.setup()

        # Force a sequence task
        mode.is_sequence = True
        mode.current_target = '=='
        mode.current_position = 0

        # Type the sequence
        for char in '==':
            event = create_key_event(char=char)
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Symbol sequence caused error: {e}")


class TestSnakeAppleGameplay:
    """Test Snake Apple mode gameplay."""

    @pytest.mark.asyncio
    async def test_hjkl_navigation(self):
        """Test hjkl navigation doesn't crash."""
        config = create_test_config()
        player = create_test_player()
        mode = SnakeAppleMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Test hjkl motions
        motions = ['h', 'j', 'k', 'l']
        for motion in motions:
            event = create_key_event(char=motion)
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Navigation motion '{motion}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_word_motions(self):
        """Test word motions in navigation."""
        config = create_test_config()
        player = create_test_player()
        mode = SnakeAppleMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Test word motions
        motions = ['w', 'b', 'e', '0', '$']
        for motion in motions:
            event = create_key_event(char=motion)
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Word motion '{motion}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_uppercase_motions(self):
        """Test uppercase motions (G, W, B, E)."""
        config = create_test_config()
        player = create_test_player()
        mode = SnakeAppleMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Test uppercase motions
        for motion in ['G', 'W', 'B', 'E']:
            # Send Shift (should be ignored)
            shift_event = create_key_event(key_name='Shift', modifiers={'shift'})
            await mode.update(shift_event)

            # Send uppercase letter
            event = create_key_event(char=motion, modifiers={'shift'})
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Uppercase motion '{motion}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_gg_sequence(self):
        """Test 'gg' two-key sequence."""
        config = create_test_config()
        player = create_test_player()
        mode = SnakeAppleMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Type 'gg'
        try:
            result1 = await mode.update(create_key_event(char='g'))
            assert result1 is False  # First 'g' should not complete

            result2 = await mode.update(create_key_event(char='g'))
            assert isinstance(result2, bool)  # Second 'g' completes 'gg'
        except Exception as e:
            pytest.fail(f"'gg' sequence caused error: {e}")


class TestCodingLessonsGameplay:
    """Test Coding Lessons mode gameplay."""

    @pytest.mark.asyncio
    async def test_typing_code(self):
        """Test typing code character by character."""
        config = create_test_config()
        player = create_test_player()
        mode = CodingLessonsMode(config, player)

        await mode.setup()

        # Set a simple target code
        mode.target_code = "def test():"
        mode.current_position = 0

        # Type the code
        for char in "def ":
            event = create_key_event(char=char)
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Typing char '{char}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_special_keys(self):
        """Test special keys like Enter, Tab, Space."""
        config = create_test_config()
        player = create_test_player()
        mode = CodingLessonsMode(config, player)

        await mode.setup()

        # Test Enter
        mode.target_code = "\n"
        mode.current_position = 0
        try:
            event = create_key_event(key_name='Enter')
            result = await mode.update(event)
            assert isinstance(result, bool)
        except Exception as e:
            pytest.fail(f"Enter key caused error: {e}")

        # Test Tab
        mode.target_code = "\t"
        mode.current_position = 0
        try:
            event = create_key_event(key_name='Tab')
            result = await mode.update(event)
            assert isinstance(result, bool)
        except Exception as e:
            pytest.fail(f"Tab key caused error: {e}")

        # Test Space
        mode.target_code = " "
        mode.current_position = 0
        try:
            event = create_key_event(key_name='Space')
            result = await mode.update(event)
            assert isinstance(result, bool)
        except Exception as e:
            pytest.fail(f"Space key caused error: {e}")

    @pytest.mark.asyncio
    async def test_uppercase_letters(self):
        """Test typing uppercase letters with Shift."""
        config = create_test_config()
        player = create_test_player()
        mode = CodingLessonsMode(config, player)

        await mode.setup()
        mode.target_code = "Test"
        mode.current_position = 0

        # Type 'T' (with Shift)
        shift_event = create_key_event(key_name='Shift', modifiers={'shift'})
        await mode.update(shift_event)  # Should be ignored

        try:
            event = create_key_event(char='T', modifiers={'shift'})
            result = await mode.update(event)
            assert isinstance(result, bool)
        except Exception as e:
            pytest.fail(f"Uppercase letter with Shift caused error: {e}")


class TestCustomKeybindingsGameplay:
    """Test Custom Keybindings mode gameplay."""

    @pytest.mark.asyncio
    async def test_simple_keybinding(self):
        """Test typing a simple keybinding."""
        config = create_test_config()
        player = create_test_player()
        mode = CustomKeybindingsMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # The mode should have fallback keymaps
        assert len(mode.custom_keymaps) > 0

        # Try typing some keys
        for char in ['g', 'g']:  # Type 'gg'
            event = create_key_event(char=char)
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Keybinding char '{char}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_ctrl_combinations(self):
        """Test Ctrl key combinations."""
        config = create_test_config()
        player = create_test_player()
        mode = CustomKeybindingsMode(config, player)

        await mode.setup()

        # Set up a Ctrl-r task
        mode.current_keymap = mode.custom_keymaps[10]  # <C-r> for redo
        mode.typed_sequence = ""

        # Send Ctrl (should be ignored)
        ctrl_event = create_key_event(key_name='Ctrl', modifiers={'ctrl'})
        await mode.update(ctrl_event)

        # Send r with Ctrl
        try:
            event = create_key_event(char='r', modifiers={'ctrl'})
            result = await mode.update(event)
            assert isinstance(result, bool)
        except Exception as e:
            pytest.fail(f"Ctrl+r caused error: {e}")


class TestVimMotionsGameplay:
    """Test Vim Motions mode gameplay."""

    @pytest.mark.asyncio
    async def test_motion_recording(self):
        """Test that motions are recorded without crashing."""
        config = create_test_config()
        player = create_test_player()
        mode = VimMotionsMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Type some motions
        motions = ['d', 'd', 'w', 'i', 'j', 'k']
        for motion in motions:
            event = create_key_event(char=motion)
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Motion '{motion}' caused error: {e}")

    @pytest.mark.asyncio
    async def test_enter_to_complete(self):
        """Test pressing Enter to mark task complete."""
        config = create_test_config()
        player = create_test_player()
        mode = VimMotionsMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Type minimum required keys
        for _ in range(5):
            event = create_key_event(char='j')
            await mode.update(event)

        # Press Enter
        try:
            enter_event = create_key_event(key_name='Enter')
            result = await mode.update(enter_event)
            assert isinstance(result, bool)
        except Exception as e:
            pytest.fail(f"Enter key caused error: {e}")


class TestComprehensiveKeysGameplay:
    """Test Comprehensive Keys mode gameplay."""

    @pytest.mark.asyncio
    async def test_various_keys(self):
        """Test that various key types work."""
        config = create_test_config()
        player = create_test_player()
        mode = ComprehensiveKeysMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Test letters
        for char in ['a', 'z', 'A', 'Z']:
            event = create_key_event(char=char)
            try:
                result = await mode.update(event)
                assert isinstance(result, bool)
            except Exception as e:
                pytest.fail(f"Key '{char}' caused error: {e}")


class TestModifierKeyHandling:
    """Test that all modes handle modifier keys correctly."""

    @pytest.mark.asyncio
    async def test_all_modes_ignore_standalone_modifiers(self):
        """Test that all game modes ignore standalone modifier keys."""
        config = create_test_config()
        player = create_test_player()

        modes = [
            WordTrainingMode(config, player),
            SymbolTrainingMode(config, player),
            SnakeAppleMode(config, player),
            CodingLessonsMode(config, player),
            CustomKeybindingsMode(config, player),
            VimMotionsMode(config, player),
            ComprehensiveKeysMode(config, player),
        ]

        modifiers = ['Shift', 'Ctrl', 'Alt', 'Cmd']

        for mode in modes:
            await mode.setup()
            await mode.generate_task()

            for mod in modifiers:
                event = create_key_event(key_name=mod, modifiers={mod.lower()})
                try:
                    result = await mode.update(event)
                    # Standalone modifiers should return False or be ignored
                    assert result is False, f"{mode.__class__.__name__} didn't ignore standalone {mod}"
                except Exception as e:
                    pytest.fail(f"{mode.__class__.__name__} crashed on {mod}: {e}")


class TestFullGameplaySessions:
    """Test complete gameplay sessions."""

    @pytest.mark.asyncio
    async def test_word_training_session(self):
        """Simulate a complete Word Training session."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTrainingMode(config, player)

        await mode.setup()

        # Complete 3 tasks
        for _ in range(3):
            await mode.generate_task()

            # Get display text (should work)
            display = mode.get_display_text()
            assert len(display) > 0

            # Make some moves (w, w, w)
            for _ in range(3):
                event = create_key_event(char='w')
                await mode.update(event)

    @pytest.mark.asyncio
    async def test_symbol_training_session(self):
        """Simulate a complete Symbol Training session."""
        config = create_test_config()
        player = create_test_player()
        mode = SymbolTrainingMode(config, player)

        await mode.setup()

        # Complete 5 tasks
        completed = 0
        attempts = 0
        max_attempts = 50

        while completed < 5 and attempts < max_attempts:
            attempts += 1
            await mode.generate_task()

            # Get the target
            target = mode.current_target
            if not target:
                continue

            # Type the target
            for char in target:
                event = create_key_event(char=char)
                result = await mode.update(event)
                if result:
                    completed += 1
                    break

        # Should have completed at least 2-3 tasks
        assert completed >= 2, f"Only completed {completed} tasks in {attempts} attempts"


class TestDisplayFunctions:
    """Test that display functions work without crashing."""

    @pytest.mark.asyncio
    async def test_all_modes_display_text(self):
        """Test get_display_text() for all modes."""
        config = create_test_config()
        player = create_test_player()

        modes = [
            WordTrainingMode(config, player),
            SymbolTrainingMode(config, player),
            SnakeAppleMode(config, player),
            CodingLessonsMode(config, player),
            CustomKeybindingsMode(config, player),
            VimMotionsMode(config, player),
            ComprehensiveKeysMode(config, player),
        ]

        for mode in modes:
            await mode.setup()
            await mode.generate_task()

            try:
                # Before any input
                display1 = mode.get_display_text()
                assert isinstance(display1, str)
                assert len(display1) > 0

                # After some input
                event = create_key_event(char='a')
                await mode.update(event)

                display2 = mode.get_display_text()
                assert isinstance(display2, str)
                assert len(display2) > 0

            except Exception as e:
                pytest.fail(f"{mode.__class__.__name__}.get_display_text() crashed: {e}")


if __name__ == "__main__":
    # Allow running directly
    pytest.main([__file__, "-v", "--tb=short"])
