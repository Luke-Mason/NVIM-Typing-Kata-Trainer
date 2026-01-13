"""Snake Apple Mode - Navigate to target characters using vim motions."""
import random
import time
from typing import List, Tuple, Optional

from .base_mode import BaseGameMode
from ..core.config import Config
from ..models.player import Player
from ..input.keyboard_handler import KeyEvent
from ..utils.stats_calculator import calculate_xp_bonus


class SnakeAppleMode(BaseGameMode):
    """Game mode for navigating to target characters using vim motions."""

    # Text grids for navigation practice
    PRACTICE_GRIDS = [
        [
            "The quick brown fox jumps over the lazy dog",
            "Python is a versatile programming language",
            "Vim makes editing text incredibly efficient",
            "Practice these motions to improve your speed",
            "Navigate to the apple using hjkl and other keys"
        ],
        [
            "def hello_world():",
            "    print('Hello, World!')",
            "    return True",
            "",
            "if __name__ == '__main__':",
            "    hello_world()"
        ],
        [
            "class Calculator:",
            "    def __init__(self):",
            "        self.result = 0",
            "    ",
            "    def add(self, x, y):",
            "        return x + y"
        ],
        [
            "Lorem ipsum dolor sit amet consectetur",
            "adipiscing elit sed do eiusmod tempor",
            "incididunt ut labore et dolore magna",
            "aliqua Ut enim ad minim veniam quis",
            "nostrud exercitation ullamco laboris"
        ]
    ]

    # Vim navigation motions
    NAVIGATION_MOTIONS = {
        # Basic motions
        'h': (-1, 0),   # left
        'j': (0, 1),    # down
        'k': (0, -1),   # up
        'l': (1, 0),    # right
        # Line motions
        '0': 'line_start',
        '^': 'line_first_char',
        '$': 'line_end',
        # Word motions
        'w': 'word_forward',
        'b': 'word_back',
        'e': 'word_end',
        # Find motions
        'f': 'find_char',
        'F': 'find_char_back',
        # Line jump
        'gg': 'first_line',
        'G': 'last_line',
    }

    def __init__(self, config: Config, player: Player):
        """
        Initialize Snake Apple mode.

        Args:
            config: Application configuration
            player: Player instance
        """
        super().__init__(config, player, mode_name="snake_apple")

        self.grid: List[str] = []
        self.cursor_row: int = 0
        self.cursor_col: int = 0
        self.apple_row: int = 0
        self.apple_col: int = 0
        self.task_start_time: float = 0
        self.moves_made: int = 0
        self.last_key: str = ""

    async def setup(self):
        """Initialize the game mode."""
        pass

    async def generate_task(self):
        """Generate a new navigation task."""
        # Select random grid
        self.grid = random.choice(self.PRACTICE_GRIDS).copy()

        # Start at top-left
        self.cursor_row = 0
        self.cursor_col = 0

        # Place apple at random position (not at start)
        self._place_apple()

        self.moves_made = 0
        self.task_start_time = time.time()

    def _place_apple(self):
        """Place the apple at a random position."""
        # Find valid positions (non-empty characters)
        valid_positions = []
        for row_idx, row in enumerate(self.grid):
            for col_idx, char in enumerate(row):
                if char not in (' ', '') and not (row_idx == 0 and col_idx == 0):
                    valid_positions.append((row_idx, col_idx))

        if valid_positions:
            self.apple_row, self.apple_col = random.choice(valid_positions)
        else:
            # Fallback
            self.apple_row = len(self.grid) - 1
            self.apple_col = len(self.grid[-1]) - 1 if self.grid else 0

    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a vim navigation key.

        Args:
            key_event: The key event

        Returns:
            True if reached the apple
        """
        # Ignore modifier keys
        if key_event.key_name in ['Shift', 'Ctrl', 'Alt', 'Cmd']:
            return False

        key = key_event.char if key_event.char else key_event.key_name

        # Handle multi-key sequences like 'gg'
        if self.last_key == 'g' and key == 'g':
            key = 'gg'
            self.last_key = ""
        elif key == 'g':
            self.last_key = key
            return False
        else:
            self.last_key = ""

        # Check if it's a valid motion
        if key not in self.NAVIGATION_MOTIONS:
            self.session.record_keystroke(correct=False)
            return False

        # Execute motion
        old_row, old_col = self.cursor_row, self.cursor_col
        self._execute_motion(key)
        self.moves_made += 1

        # Check if position changed (valid move)
        if (self.cursor_row, self.cursor_col) != (old_row, old_col):
            self.session.record_keystroke(correct=True)
        else:
            self.session.record_keystroke(correct=False)

        # Check if we reached the apple
        if self.cursor_row == self.apple_row and self.cursor_col == self.apple_col:
            # Success!
            reaction_time = time.time() - self.task_start_time

            # Calculate XP with efficiency bonus
            distance = abs(self.apple_row - 0) + abs(self.apple_col - 0)
            efficiency = distance / self.moves_made if self.moves_made > 0 else 1.0
            efficiency_bonus = min(2.0, max(0.5, efficiency * 1.5))

            speed_factor = max(0.5, min(2.0, 2.0 - (reaction_time / 10.0)))

            xp = calculate_xp_bonus(
                accuracy=100.0,
                speed_factor=speed_factor * efficiency_bonus,
                streak_count=self.session.current_streak,
                base_xp=20  # Higher base XP
            )

            # Record success
            self.on_task_complete(xp)

            # Store stats
            stats = self.session.get_mode_data('snake_apple_stats', {
                'total_moves': 0,
                'total_distance': 0,
                'reaction_times': []
            })
            stats['total_moves'] += self.moves_made
            stats['total_distance'] += distance
            stats['reaction_times'].append(reaction_time)
            self.session.set_mode_data('snake_apple_stats', stats)

            return True

        return False

    def _execute_motion(self, motion: str):
        """
        Execute a vim navigation motion.

        Args:
            motion: Motion command
        """
        if not self.grid:
            return

        current_line = self.grid[self.cursor_row] if self.cursor_row < len(self.grid) else ""

        if motion in ['h', 'j', 'k', 'l']:
            # Basic hjkl movement
            delta = self.NAVIGATION_MOTIONS[motion]
            new_col = self.cursor_col + delta[0]
            new_row = self.cursor_row + delta[1]

            # Clamp to valid positions
            if 0 <= new_row < len(self.grid):
                self.cursor_row = new_row
                line_len = len(self.grid[new_row])
                self.cursor_col = max(0, min(new_col, line_len - 1 if line_len > 0 else 0))

        elif motion == '0':
            # Start of line
            self.cursor_col = 0

        elif motion == '^':
            # First non-blank character
            for i, char in enumerate(current_line):
                if char != ' ':
                    self.cursor_col = i
                    break

        elif motion == '$':
            # End of line
            self.cursor_col = max(0, len(current_line) - 1)

        elif motion == 'w':
            # Word forward
            self._move_word_forward()

        elif motion == 'b':
            # Word back
            self._move_word_back()

        elif motion == 'e':
            # End of word
            self._move_word_end()

        elif motion == 'gg':
            # First line
            self.cursor_row = 0
            self.cursor_col = 0

        elif motion == 'G':
            # Last line
            self.cursor_row = len(self.grid) - 1
            self.cursor_col = 0

    def _move_word_forward(self):
        """Move cursor to start of next word."""
        if self.cursor_row >= len(self.grid):
            return

        line = self.grid[self.cursor_row]
        words = line.split()

        # Find next word
        char_pos = 0
        for word in words:
            word_start = line.find(word, char_pos)
            if word_start > self.cursor_col:
                self.cursor_col = word_start
                return
            char_pos = word_start + len(word)

        # No more words on this line, go to next line
        if self.cursor_row + 1 < len(self.grid):
            self.cursor_row += 1
            self.cursor_col = 0

    def _move_word_back(self):
        """Move cursor to start of previous word."""
        if self.cursor_row >= len(self.grid):
            return

        line = self.grid[self.cursor_row]
        words = line.split()

        # Find previous word
        for i in range(len(words) - 1, -1, -1):
            word_start = line.find(words[i])
            if word_start < self.cursor_col:
                self.cursor_col = word_start
                return

        # No previous word on this line, go to previous line end
        if self.cursor_row > 0:
            self.cursor_row -= 1
            self.cursor_col = len(self.grid[self.cursor_row]) - 1

    def _move_word_end(self):
        """Move cursor to end of current/next word."""
        if self.cursor_row >= len(self.grid):
            return

        line = self.grid[self.cursor_row]
        words = line.split()

        char_pos = 0
        for word in words:
            word_start = line.find(word, char_pos)
            word_end = word_start + len(word) - 1
            if word_end > self.cursor_col:
                self.cursor_col = word_end
                return
            char_pos = word_start + len(word)

    def get_display_text(self) -> str:
        """
        Get display text showing the grid with cursor and apple.

        Returns:
            Rich-formatted display text
        """
        lines = []

        lines.append("[bold cyan]🍎 Snake Apple - Vim Navigation[/]")
        lines.append("")
        lines.append("[yellow]Navigate to the [bold red]APPLE[/yellow][yellow] using vim motions[/]")
        lines.append("")

        # Display grid with cursor and apple
        for row_idx, row in enumerate(self.grid):
            line_chars = []
            for col_idx, char in enumerate(row):
                if row_idx == self.cursor_row and col_idx == self.cursor_col:
                    # Cursor position
                    if row_idx == self.apple_row and col_idx == self.apple_col:
                        line_chars.append("[bold green on yellow]▸[/]")
                    else:
                        line_chars.append("[bold green on black]▸[/]")
                elif row_idx == self.apple_row and col_idx == self.apple_col:
                    # Apple position
                    line_chars.append("[bold red on yellow]🍎[/]")
                else:
                    line_chars.append(char)
            lines.append(''.join(line_chars))

        lines.append("")
        lines.append(f"[cyan]Moves:[/] {self.moves_made}")
        lines.append(f"[cyan]Tasks Completed:[/] {self.session.tasks_completed}")
        lines.append(f"[cyan]Current Streak:[/] {self.session.current_streak}")
        lines.append(f"[cyan]XP Earned:[/] {self.session.xp_earned:,}")

        # Show efficiency
        stats = self.session.get_mode_data('snake_apple_stats', {})
        if stats and 'total_moves' in stats:
            efficiency = (stats['total_distance'] / stats['total_moves'] * 100) if stats['total_moves'] > 0 else 100
            lines.append(f"[cyan]Efficiency:[/] {efficiency:.1f}%")

        lines.append("")
        lines.append(f"[dim]Motions: hjkl, w, b, e, 0, ^, $, gg, G | '{self.config.universal_exit_sequence}' to exit[/]")

        return "\n".join(lines)

    def calculate_score(self) -> int:
        """Calculate XP for current task."""
        return 0  # Calculated in update()
