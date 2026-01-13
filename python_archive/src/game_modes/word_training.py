"""Word Training Mode - Practice vim word motions (w, b, e, W, B, E)."""
import random
import time
from typing import List, Optional, Tuple

from .base_mode import BaseGameMode
from ..core.config import Config
from ..models.player import Player
from ..input.keyboard_handler import KeyEvent
from ..utils.stats_calculator import calculate_xp_bonus


class WordTrainingMode(BaseGameMode):
    """Game mode for training vim word motions."""

    # Sample texts with different word patterns
    PRACTICE_TEXTS = [
        "The quick brown fox jumps over the lazy dog near the riverbank",
        "Python programming requires practice and dedication to master effectively",
        "Vim motions make text editing incredibly fast and efficient once learned",
        "Machine learning models train on large datasets to improve accuracy",
        "Software development involves writing, testing, and debugging code daily",
        "The JavaScript framework enables building modern web applications quickly",
        "Database queries optimize performance by using proper indexing strategies",
        "Cloud computing provides scalable infrastructure for enterprise applications",
        "Agile methodologies emphasize iterative development and continuous feedback",
        "Open source projects benefit from community contributions and collaboration",
    ]

    # Vim word motion commands
    WORD_MOTIONS = {
        'w': 'Move to start of next word',
        'W': 'Move to start of next WORD (space-separated)',
        'b': 'Move to start of previous word',
        'B': 'Move to start of previous WORD',
        'e': 'Move to end of word',
        'E': 'Move to end of WORD',
    }

    def __init__(self, config: Config, player: Player):
        """
        Initialize Word Training mode.

        Args:
            config: Application configuration
            player: Player instance
        """
        super().__init__(config, player, mode_name="word_training")

        self.text: str = ""
        self.cursor_position: int = 0
        self.target_position: int = 0
        self.current_motion: Optional[str] = None
        self.task_start_time: float = 0
        self.moves_made: int = 0

    async def setup(self):
        """Initialize the game mode."""
        pass

    async def generate_task(self):
        """Generate a new word motion task."""
        # Select random text
        self.text = random.choice(self.PRACTICE_TEXTS)
        self.cursor_position = 0
        self.moves_made = 0

        # Select a target position using random word motions
        self.target_position = self._generate_target_position()
        self.current_motion = self._suggest_motion()

        self.task_start_time = time.time()

    def _generate_target_position(self) -> int:
        """
        Generate a target position in the text.

        Returns:
            Target cursor position
        """
        words = self.text.split()
        if not words:
            return 0

        # Choose a random word (not the first one)
        target_word_index = random.randint(1, len(words) - 1)

        # Calculate character position
        position = 0
        for i in range(target_word_index):
            position += len(words[i]) + 1  # +1 for space

        return position

    def _suggest_motion(self) -> str:
        """
        Suggest an efficient motion to reach target.

        Returns:
            Suggested motion command
        """
        if self.target_position > self.cursor_position:
            # Moving forward
            return random.choice(['w', 'W', 'e', 'E'])
        elif self.target_position < self.cursor_position:
            # Moving backward
            return random.choice(['b', 'B'])
        else:
            return 'w'

    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a key event (vim motion).

        Args:
            key_event: The key event

        Returns:
            True if task completed successfully
        """
        # Ignore modifier keys
        if key_event.key_name in ['Shift', 'Ctrl', 'Alt', 'Cmd']:
            return False

        key = key_event.char if key_event.char else key_event.key_name

        # Check if it's a valid word motion
        if key not in self.WORD_MOTIONS:
            # Invalid motion
            self.session.record_keystroke(correct=False)
            return False

        # Execute the motion
        self.moves_made += 1
        old_position = self.cursor_position
        self._execute_motion(key)

        # Check if we reached the target
        if self.cursor_position == self.target_position:
            # Success!
            reaction_time = time.time() - self.task_start_time

            # Calculate XP (bonus for fewer moves)
            optimal_moves = self._calculate_optimal_moves()
            efficiency = optimal_moves / self.moves_made if self.moves_made > 0 else 1.0
            efficiency_bonus = min(2.0, max(0.5, efficiency))

            speed_factor = max(0.5, min(2.0, 2.0 - (reaction_time / 5.0)))

            xp = calculate_xp_bonus(
                accuracy=100.0,
                speed_factor=speed_factor * efficiency_bonus,
                streak_count=self.session.current_streak,
                base_xp=15  # Higher base XP for word training
            )

            # Record success
            self.session.record_keystroke(correct=True)
            self.on_task_complete(xp)

            # Store stats
            stats = self.session.get_mode_data('word_training_stats', {
                'total_moves': 0,
                'optimal_moves': 0,
                'reaction_times': []
            })
            stats['total_moves'] += self.moves_made
            stats['optimal_moves'] += optimal_moves
            stats['reaction_times'].append(reaction_time)
            self.session.set_mode_data('word_training_stats', stats)

            return True

        # Record the move as correct if we moved
        if self.cursor_position != old_position:
            self.session.record_keystroke(correct=True)
        else:
            self.session.record_keystroke(correct=False)

        return False

    def _execute_motion(self, motion: str):
        """
        Execute a vim word motion.

        Args:
            motion: Motion command (w, b, e, etc.)
        """
        words = self.text.split()
        if not words:
            return

        # Calculate current word index
        current_word = self._position_to_word_index(self.cursor_position)

        if motion == 'w' or motion == 'W':
            # Move to start of next word
            if current_word + 1 < len(words):
                self.cursor_position = self._word_index_to_position(current_word + 1)

        elif motion == 'b' or motion == 'B':
            # Move to start of previous word
            if current_word > 0:
                self.cursor_position = self._word_index_to_position(current_word - 1)

        elif motion == 'e' or motion == 'E':
            # Move to end of current/next word
            if current_word < len(words):
                word_start = self._word_index_to_position(current_word)
                self.cursor_position = word_start + len(words[current_word]) - 1

    def _position_to_word_index(self, position: int) -> int:
        """Convert character position to word index."""
        words = self.text.split()
        char_count = 0

        for i, word in enumerate(words):
            if position <= char_count + len(word):
                return i
            char_count += len(word) + 1  # +1 for space

        return len(words) - 1

    def _word_index_to_position(self, word_index: int) -> int:
        """Convert word index to character position."""
        words = self.text.split()
        if word_index >= len(words):
            return len(self.text)

        position = 0
        for i in range(word_index):
            position += len(words[i]) + 1  # +1 for space

        return position

    def _calculate_optimal_moves(self) -> int:
        """
        Calculate optimal number of moves needed.

        Returns:
            Optimal move count
        """
        # Simple heuristic: difference in word positions
        start_word = self._position_to_word_index(0)
        target_word = self._position_to_word_index(self.target_position)
        return abs(target_word - start_word)

    def get_display_text(self) -> str:
        """
        Get display text showing the text with cursor and target.

        Returns:
            Rich-formatted display text
        """
        lines = []

        lines.append("[bold cyan]📝 Word Training[/]")
        lines.append("")
        lines.append(f"[yellow]Suggested Motion:[/] {self.current_motion} - {self.WORD_MOTIONS.get(self.current_motion, '')}")
        lines.append("")

        # Display text with cursor and target marked
        if self.text:
            display_text = self._format_text_with_markers()
            lines.append("[bold]Text:[/]")
            lines.append(display_text)
        else:
            lines.append("[dim]Loading...[/]")

        lines.append("")
        lines.append(f"[cyan]Moves Made:[/] {self.moves_made} | [cyan]Optimal:[/] {self._calculate_optimal_moves()}")
        lines.append(f"[cyan]Tasks Completed:[/] {self.session.tasks_completed}")
        lines.append(f"[cyan]Current Streak:[/] {self.session.current_streak}")
        lines.append(f"[cyan]Accuracy:[/] {self.session.calculate_accuracy():.1f}%")
        lines.append(f"[cyan]XP Earned:[/] {self.session.xp_earned:,}")

        # Show efficiency stats
        stats = self.session.get_mode_data('word_training_stats', {})
        if stats and 'total_moves' in stats:
            efficiency = (stats['optimal_moves'] / stats['total_moves'] * 100) if stats['total_moves'] > 0 else 100
            lines.append(f"[cyan]Efficiency:[/] {efficiency:.1f}%")

        lines.append("")
        lines.append(f"[dim]Use vim motions (w, b, e, W, B, E) | Press '{self.config.universal_exit_sequence}' to exit[/]")

        return "\n".join(lines)

    def _format_text_with_markers(self) -> str:
        """Format text with cursor and target positions marked."""
        result = []
        for i, char in enumerate(self.text):
            if i == self.cursor_position:
                # Current cursor position
                result.append(f"[bold green on black]▸[/]{char}")
            elif i == self.target_position:
                # Target position
                result.append(f"[bold yellow on red]{char}[/]")
            else:
                result.append(char)

        return ''.join(result)

    def calculate_score(self) -> int:
        """Calculate XP for current task."""
        return 0  # Calculated in update()
