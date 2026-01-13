"""Tests for the new Word Typing mode (monkeytype-style)."""
import pytest
from pathlib import Path

from src.core.config import Config
from src.models.player import Player
from src.input.keyboard_handler import KeyEvent
from src.game_modes.word_typing import WordTypingMode


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


class TestWordTypingMode:
    """Test the new Word Typing mode."""

    @pytest.mark.asyncio
    async def test_mode_initialization(self):
        """Test that mode initializes correctly."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        assert mode is not None
        assert mode.words_per_session == 20
        assert len(mode.COMMON_WORDS) > 100

    @pytest.mark.asyncio
    async def test_generate_task_creates_word_list(self):
        """Test that generate_task creates a word list."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        assert len(mode.word_list) == 20
        assert mode.current_word in mode.COMMON_WORDS
        assert mode.current_word_index == 0
        assert mode.typed_text == ""

    @pytest.mark.asyncio
    async def test_typing_correct_characters(self):
        """Test typing correct characters."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Get the first word
        word = mode.current_word

        # Type each character
        for char in word:
            event = create_key_event(char=char)
            result = await mode.update(event)
            assert result is False  # Not complete yet

        # Check typed text matches
        assert mode.typed_text == word

    @pytest.mark.asyncio
    async def test_space_completes_word(self):
        """Test that pressing Space completes a word."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Get the first word
        word = mode.current_word

        # Type the word
        for char in word:
            await mode.update(create_key_event(char=char))

        # Press Space to complete
        space_event = create_key_event(key_name='Space')
        result = await mode.update(space_event)

        # Should move to next word
        assert result is False  # Not session complete
        assert mode.words_completed == 1
        assert mode.current_word_index == 1
        assert mode.typed_text == ""  # Reset for next word

    @pytest.mark.asyncio
    async def test_backspace_removes_character(self):
        """Test that Backspace removes last character."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Type some characters
        await mode.update(create_key_event(char='t'))
        await mode.update(create_key_event(char='e'))
        await mode.update(create_key_event(char='s'))

        assert mode.typed_text == "tes"

        # Press Backspace
        backspace_event = create_key_event(key_name='Backspace')
        await mode.update(backspace_event)

        assert mode.typed_text == "te"

    @pytest.mark.asyncio
    async def test_ignores_modifier_keys(self):
        """Test that modifier keys are ignored."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Try modifier keys
        for mod in ['Shift', 'Ctrl', 'Alt', 'Cmd']:
            event = create_key_event(key_name=mod)
            result = await mode.update(event)
            assert result is False
            assert mode.typed_text == ""  # Nothing typed

    @pytest.mark.asyncio
    async def test_display_text_generation(self):
        """Test that display text can be generated."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        display = mode.get_display_text()
        assert isinstance(display, str)
        assert len(display) > 0
        assert "Word Typing" in display
        assert "WPM" in display

    @pytest.mark.asyncio
    async def test_wrong_character_marks_error(self):
        """Test that typing wrong character marks an error."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Get expected first character
        word = mode.current_word
        first_char = word[0]

        # Type wrong character
        wrong_char = 'z' if first_char != 'z' else 'x'
        await mode.update(create_key_event(char=wrong_char))

        # Error should be recorded
        assert mode.errors_made > 0

    @pytest.mark.asyncio
    async def test_session_completes_after_20_words(self):
        """Test that session completes after 20 words."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        # Type all 20 words
        for i in range(20):
            word = mode.word_list[i]

            # Type the word
            for char in word:
                await mode.update(create_key_event(char=char))

            # Press Space (last word should complete session)
            result = await mode.update(create_key_event(key_name='Space'))

            if i == 19:
                # Last word should complete session
                assert result is True
            else:
                # Not done yet
                assert result is False

    @pytest.mark.asyncio
    async def test_no_cheating_by_holding_key(self):
        """Test that you can't cheat by holding a key."""
        config = create_test_config()
        player = create_test_player()
        mode = WordTypingMode(config, player)

        await mode.setup()
        await mode.generate_task()

        word = mode.current_word

        # Try to cheat by typing 'w' multiple times
        for _ in range(100):
            await mode.update(create_key_event(char='w'))

        # Should not complete unless 'w' is the actual word
        if word != 'w' * 100:
            # Should have lots of errors
            assert mode.errors_made > 0
            # Should not have completed
            assert mode.words_completed == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
