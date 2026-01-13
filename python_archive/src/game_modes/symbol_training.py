"""Symbol Training Mode - Practice special characters and symbol sequences."""
import random
import time
from typing import List, Optional

from .base_mode import BaseGameMode
from ..core.config import Config
from ..models.player import Player
from ..input.keyboard_handler import KeyEvent
from ..utils.stats_calculator import calculate_xp_bonus


class SymbolTrainingMode(BaseGameMode):
    """Game mode for training special characters and symbols."""

    # Symbol categories for training
    SYMBOL_CATEGORIES = {
        'brackets': ['(', ')', '[', ']', '{', '}', '<', '>'],
        'operators': ['+', '-', '*', '/', '=', '!', '&', '|', '^', '~', '%'],
        'punctuation': ['.', ',', ';', ':', '?', '!', "'", '"'],
        'special': ['@', '#', '$', '%', '^', '&', '*', '_', '`', '\\'],
        'quotes': ['"', "'", '`'],
        'math': ['+', '-', '=', '/', '*', '%', '^'],
    }

    # Common symbol sequences in programming
    SYMBOL_SEQUENCES = [
        # Python
        ['=', '='],  # ==
        ['!', '='],  # !=
        ['<', '='],  # <=
        ['>', '='],  # >=
        ['+', '+'],  # ++
        ['-', '-'],  # --
        ['+', '='],  # +=
        ['-', '='],  # -=
        ['*', '='],  # *=
        ['/', '='],  # /=
        ['&', '&'],  # &&
        ['|', '|'],  # ||
        ['-', '>'],  # ->
        ['=', '>'],  # =>
        [':', ':'],  # ::
        # Brackets
        ['(', ')'],
        ['[', ']'],
        ['{', '}'],
        ['<', '>'],
        # Quotes
        ['"', '"'],
        ["'", "'"],
        ['`', '`'],
    ]

    # Common programming patterns
    PROGRAMMING_PATTERNS = [
        '();',
        '[]',
        '{}',
        '<>',
        '""',
        "''",
        '``',
        '->',
        '=>',
        '!=',
        '==',
        '<=',
        '>=',
        '&&',
        '||',
        '+=',
        '-=',
        '*=',
        '/=',
        '::',
        '()',
    ]

    def __init__(self, config: Config, player: Player):
        """
        Initialize Symbol Training mode.

        Args:
            config: Application configuration
            player: Player instance
        """
        super().__init__(config, player, mode_name="symbol_training")

        self.current_target: Optional[str] = None  # Can be single symbol or sequence
        self.current_category: Optional[str] = None
        self.current_position: int = 0  # For multi-character sequences
        self.task_start_time: float = 0
        self.is_sequence: bool = False

    async def setup(self):
        """Initialize the game mode."""
        pass  # No special setup needed

    async def generate_task(self):
        """Generate the next symbol or sequence to practice."""
        # 70% chance for single symbol, 30% for sequence
        self.is_sequence = random.random() < 0.3

        if self.is_sequence:
            # Generate a sequence task
            if random.random() < 0.5:
                # Use predefined pattern
                self.current_target = random.choice(self.PROGRAMMING_PATTERNS)
                self.current_category = "programming_pattern"
            else:
                # Use symbol sequence
                seq = random.choice(self.SYMBOL_SEQUENCES)
                self.current_target = ''.join(seq)
                self.current_category = "symbol_sequence"
        else:
            # Generate single symbol task
            self.current_category = random.choice(list(self.SYMBOL_CATEGORIES.keys()))
            self.current_target = random.choice(self.SYMBOL_CATEGORIES[self.current_category])

        self.current_position = 0
        self.task_start_time = time.time()

    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a key event.

        Args:
            key_event: The key event

        Returns:
            True if task completed successfully
        """
        if self.current_target is None:
            return False

        # Ignore modifier keys
        if key_event.key_name in ['Shift', 'Ctrl', 'Alt', 'Cmd']:
            return False

        # Get expected character at current position
        expected_char = self.current_target[self.current_position]

        # Check if typed character matches
        typed_char = key_event.char if key_event.char else key_event.key_name

        if typed_char == expected_char:
            # Correct character
            self.current_position += 1

            # Check if sequence is complete
            if self.current_position >= len(self.current_target):
                # Sequence complete!
                reaction_time = time.time() - self.task_start_time

                # Calculate XP with bonus for sequences
                sequence_bonus = 1.5 if self.is_sequence and len(self.current_target) > 1 else 1.0
                speed_factor = max(0.5, min(2.0, 2.0 - (reaction_time / 3.0)))

                xp = calculate_xp_bonus(
                    accuracy=100.0,
                    speed_factor=speed_factor,
                    streak_count=self.session.current_streak,
                    base_xp=int(10 * sequence_bonus)
                )

                # Record success
                self.session.record_keystroke(correct=True)
                self.on_task_complete(xp)

                # Store reaction time
                reaction_times = self.session.get_mode_data('reaction_times', [])
                reaction_times.append(reaction_time)
                self.session.set_mode_data('reaction_times', reaction_times)

                return True

            # Character correct but sequence not done yet
            return False

        # Wrong character
        self.session.record_keystroke(correct=False)

        # Reset position on error
        self.current_position = 0

        return False

    def get_display_text(self) -> str:
        """
        Get display text for the current state.

        Returns:
            Rich-formatted display text
        """
        lines = []

        lines.append("[bold cyan]🔣 Symbol Training[/]")
        lines.append("")
        lines.append(f"[yellow]Category:[/] {self._format_category()}")
        lines.append("")

        if self.current_target:
            lines.append("[bold green]Type This:[/]")

            # Show progress for sequences
            if len(self.current_target) > 1:
                # Show completed part in green, current in yellow, remaining in dim
                completed = self.current_target[:self.current_position]
                current = self.current_target[self.current_position] if self.current_position < len(self.current_target) else ''
                remaining = self.current_target[self.current_position + 1:] if self.current_position + 1 < len(self.current_target) else ''

                display = ""
                if completed:
                    display += f"[green]{completed}[/]"
                if current:
                    display += f"[bold yellow on blue] {current} [/]"
                if remaining:
                    display += f"[dim]{remaining}[/]"

                lines.append(f"   {display}")
            else:
                # Single symbol
                lines.append(f"[bold yellow on blue]   {self.current_target}   [/]")
        else:
            lines.append("[dim]Generating next symbol...[/]")

        lines.append("")
        lines.append(f"[cyan]Tasks Completed:[/] {self.session.tasks_completed}")
        lines.append(f"[cyan]Current Streak:[/] {self.session.current_streak}")
        lines.append(f"[cyan]Best Streak:[/] {self.session.best_streak}")
        lines.append(f"[cyan]Accuracy:[/] {self.session.calculate_accuracy():.1f}%")
        lines.append(f"[cyan]XP Earned:[/] {self.session.xp_earned:,}")

        # Show average reaction time
        reaction_times = self.session.get_mode_data('reaction_times', [])
        if reaction_times:
            avg_time = sum(reaction_times) / len(reaction_times)
            lines.append(f"[cyan]Avg Time:[/] {avg_time:.3f}s")

        lines.append("")
        lines.append(f"[dim]Press '{self.config.universal_exit_sequence}' to exit[/]")

        return "\n".join(lines)

    def _format_category(self) -> str:
        """Format category name for display."""
        if not self.current_category:
            return "N/A"

        # Convert snake_case to Title Case
        return self.current_category.replace('_', ' ').title()

    def calculate_score(self) -> int:
        """
        Calculate XP for current task.

        Returns:
            XP amount
        """
        # Calculated in update() method
        return 0

    def get_category_stats(self) -> dict:
        """
        Get statistics by category.

        Returns:
            Dictionary of category stats
        """
        # Could track which categories practiced
        return {}
