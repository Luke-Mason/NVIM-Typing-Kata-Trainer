"""Word Typing Mode - Type actual words like monkeytype (WPM training)."""
import random
import time
from typing import List, Optional

from .base_mode import BaseGameMode
from ..core.config import Config
from ..models.player import Player
from ..input.keyboard_handler import KeyEvent
from ..utils.stats_calculator import calculate_xp_bonus, calculate_wpm


class WordTypingMode(BaseGameMode):
    """Game mode for typing real words to improve WPM and accuracy."""

    # Common English words for typing practice (from monkeytype's common word list)
    COMMON_WORDS = [
        # Top 100 most common English words
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "I",
        "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
        "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
        "or", "an", "will", "my", "one", "all", "would", "there", "their", "what",
        "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
        "when", "make", "can", "like", "time", "no", "just", "him", "know", "take",
        "people", "into", "year", "your", "good", "some", "could", "them", "see", "other",
        "than", "then", "now", "look", "only", "come", "its", "over", "think", "also",
        "back", "after", "use", "two", "how", "our", "work", "first", "well", "way",
        "even", "new", "want", "because", "any", "these", "give", "day", "most", "us",

        # Additional common words
        "very", "where", "much", "through", "before", "line", "right", "too", "means", "old",
        "any", "same", "tell", "boy", "follow", "came", "want", "show", "also", "around",
        "form", "three", "small", "set", "put", "end", "does", "another", "well", "large",
        "must", "big", "even", "such", "here", "take", "why", "help", "put", "different",
        "away", "again", "off", "went", "old", "number", "great", "tell", "men", "say",
        "small", "every", "found", "still", "between", "name", "should", "home", "big", "give",
        "air", "line", "set", "own", "under", "read", "last", "never", "us", "left",
        "end", "along", "while", "might", "next", "sound", "below", "saw", "something", "thought",
        "both", "few", "those", "always", "looked", "show", "large", "often", "together", "asked",
        "house", "world", "going", "want", "school", "important", "until", "form", "food", "keep",

        # Programming-related words
        "function", "variable", "class", "method", "return", "import", "export", "const", "let",
        "array", "object", "string", "number", "boolean", "null", "undefined", "true", "false",
        "if", "else", "while", "for", "switch", "case", "break", "continue", "try", "catch",
        "async", "await", "promise", "callback", "loop", "condition", "statement", "expression",
        "parameter", "argument", "type", "interface", "enum", "struct", "pointer", "reference",
    ]

    def __init__(self, config: Config, player: Player):
        """
        Initialize Word Typing mode.

        Args:
            config: Application configuration
            player: Player instance
        """
        super().__init__(config, player, mode_name="word_typing")

        self.word_list: List[str] = []
        self.current_word_index: int = 0
        self.current_word: str = ""
        self.typed_text: str = ""
        self.session_start_time: float = 0
        self.word_start_time: float = 0
        self.words_completed: int = 0
        self.total_chars_typed: int = 0
        self.errors_made: int = 0

        # Session settings
        self.words_per_session: int = 20  # Number of words to type

    async def setup(self):
        """Initialize the game mode."""
        pass

    async def generate_task(self):
        """Generate a new typing session with random words."""
        # Generate random word list
        self.word_list = random.sample(self.COMMON_WORDS, min(self.words_per_session, len(self.COMMON_WORDS)))
        self.current_word_index = 0
        self.current_word = self.word_list[0]
        self.typed_text = ""
        self.session_start_time = time.time()
        self.word_start_time = time.time()
        self.words_completed = 0
        self.total_chars_typed = 0
        self.errors_made = 0

    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a key event (typing a character).

        Args:
            key_event: The key event

        Returns:
            True if session completed successfully
        """
        # Ignore modifier keys
        if key_event.key_name in ['Shift', 'Ctrl', 'Alt', 'Cmd']:
            return False

        # Handle backspace
        if key_event.key_name == 'Backspace':
            if self.typed_text:
                self.typed_text = self.typed_text[:-1]
            return False

        # Get typed character
        if key_event.key_name == 'Space':
            typed_char = ' '
        elif key_event.char:
            typed_char = key_event.char
        else:
            # Unknown key, ignore
            return False

        # Handle space (word completion)
        if typed_char == ' ':
            # Check if current word is correct
            if self.typed_text == self.current_word:
                # Correct word!
                self.words_completed += 1
                self.total_chars_typed += len(self.current_word) + 1  # +1 for space
                self.session.record_keystroke(correct=True)

                # Move to next word
                self.current_word_index += 1
                if self.current_word_index >= len(self.word_list):
                    # Session complete!
                    return await self._complete_session()

                self.current_word = self.word_list[self.current_word_index]
                self.typed_text = ""
                self.word_start_time = time.time()
                return False
            else:
                # Wrong word - mark error but allow correction
                self.errors_made += 1
                self.session.record_keystroke(correct=False)
                return False

        # Add character to typed text
        self.typed_text += typed_char

        # Check if character is correct
        if len(self.typed_text) <= len(self.current_word):
            expected_char = self.current_word[len(self.typed_text) - 1]
            if typed_char == expected_char:
                self.session.record_keystroke(correct=True)
            else:
                self.session.record_keystroke(correct=False)
                self.errors_made += 1
        else:
            # Typed too many characters
            self.session.record_keystroke(correct=False)
            self.errors_made += 1

        return False

    async def _complete_session(self) -> bool:
        """Complete the typing session and calculate results."""
        session_duration = time.time() - self.session_start_time

        # Calculate metrics
        wpm = calculate_wpm(self.total_chars_typed, session_duration)
        accuracy = ((self.total_chars_typed - self.errors_made) / self.total_chars_typed * 100) if self.total_chars_typed > 0 else 100

        # Calculate XP
        wpm_bonus = min(2.0, wpm / 40.0)  # 40 WPM = 1.0x, 80+ WPM = 2.0x
        accuracy_bonus = accuracy / 100.0

        xp = calculate_xp_bonus(
            accuracy=accuracy,
            speed_factor=wpm_bonus,
            streak_count=self.session.current_streak,
            base_xp=50  # Higher base XP for completing full session
        )

        # Record completion
        self.on_task_complete(xp)

        # Store stats
        stats = self.session.get_mode_data('word_typing_stats', {
            'total_words': 0,
            'total_chars': 0,
            'total_errors': 0,
            'total_time': 0.0,
            'sessions_completed': 0,
            'best_wpm': 0.0,
            'best_accuracy': 0.0,
        })
        stats['total_words'] += self.words_completed
        stats['total_chars'] += self.total_chars_typed
        stats['total_errors'] += self.errors_made
        stats['total_time'] += session_duration
        stats['sessions_completed'] += 1
        stats['best_wpm'] = max(stats['best_wpm'], wpm)
        stats['best_accuracy'] = max(stats['best_accuracy'], accuracy)
        self.session.set_mode_data('word_typing_stats', stats)

        return True

    def get_display_text(self) -> str:
        """
        Get display text showing typing progress.

        Returns:
            Rich-formatted display text
        """
        lines = []

        lines.append("[bold cyan]📝 Word Typing - WPM Training[/]")
        lines.append("")

        # Show progress
        progress = f"{self.words_completed + 1}/{len(self.word_list)}"
        lines.append(f"[yellow]Progress:[/] {progress}")
        lines.append("")

        # Show current word with typed portion
        if self.current_word:
            typed_correct = ""
            typed_wrong = ""
            remaining = self.current_word

            # Check what's been typed
            for i, char in enumerate(self.typed_text):
                if i < len(self.current_word):
                    if char == self.current_word[i]:
                        typed_correct += char
                    else:
                        typed_wrong += char
                else:
                    typed_wrong += char

            # Remaining characters
            remaining = self.current_word[len(self.typed_text):]

            # Display with colors
            display_word = ""
            if typed_correct:
                display_word += f"[green]{typed_correct}[/]"
            if typed_wrong:
                display_word += f"[red on black]{typed_wrong}[/]"
            if remaining:
                display_word += f"[dim]{remaining}[/]"

            lines.append("[bold]Type this word:[/]")
            lines.append(f"  {display_word}")
        else:
            lines.append("[dim]Loading...[/]")

        lines.append("")

        # Show next few words
        if self.current_word_index + 1 < len(self.word_list):
            next_words = self.word_list[self.current_word_index + 1:self.current_word_index + 4]
            lines.append(f"[dim]Next: {' '.join(next_words)}[/]")
            lines.append("")

        # Show live WPM
        if self.session_start_time > 0:
            elapsed = time.time() - self.session_start_time
            if elapsed > 0:
                current_wpm = calculate_wpm(self.total_chars_typed, elapsed)
                lines.append(f"[cyan]Current WPM:[/] {current_wpm:.1f}")

        # Show stats
        lines.append(f"[cyan]Words Completed:[/] {self.words_completed}")
        lines.append(f"[cyan]Errors:[/] {self.errors_made}")
        if self.total_chars_typed > 0:
            accuracy = ((self.total_chars_typed - self.errors_made) / self.total_chars_typed * 100)
            lines.append(f"[cyan]Accuracy:[/] {accuracy:.1f}%")
        lines.append(f"[cyan]XP Earned:[/] {self.session.xp_earned:,}")

        # Show session stats
        stats = self.session.get_mode_data('word_typing_stats', {})
        if stats and 'best_wpm' in stats:
            lines.append(f"[cyan]Best WPM:[/] {stats['best_wpm']:.1f}")

        lines.append("")
        lines.append(f"[dim]Type each word and press Space | Backspace to correct | '{self.config.universal_exit_sequence}' to exit[/]")

        return "\n".join(lines)

    def calculate_score(self) -> int:
        """Calculate XP for current task."""
        return 0  # Calculated in _complete_session()
