"""Comprehensive Keys Mode - Train all keyboard keys."""
import random
import time
from typing import List, Optional

from .base_mode import BaseGameMode
from ..core.config import Config
from ..models.player import Player
from ..input.keyboard_handler import KeyEvent
from ..utils.stats_calculator import calculate_xp_bonus


class ComprehensiveKeysMode(BaseGameMode):
    """Game mode for training all keyboard keys including special keys."""

    KEY_CATEGORIES = {
        'letters': list('abcdefghijklmnopqrstuvwxyz'),
        'numbers': list('0123456789'),
        'symbols': list('!@#$%^&*()_+-=[]{}|;:\'",.<>?/`~'),
        'function': ['F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12'],
        'navigation': ['Up', 'Down', 'Left', 'Right', 'Home', 'End', 'PageUp', 'PageDown'],
        'special': ['Esc', 'Enter', 'Tab', 'Space', 'Backspace', 'Delete'],
    }

    def __init__(self, config: Config, player: Player):
        """
        Initialize Comprehensive Keys mode.

        Args:
            config: Application configuration
            player: Player instance
        """
        super().__init__(config, player, mode_name="comprehensive_keys")

        self.current_target_key: Optional[str] = None
        self.current_category: Optional[str] = None
        self.task_start_time: float = 0
        self.tasks_in_current_session: int = 0

    async def setup(self):
        """Initialize the game mode."""
        pass  # No special setup needed

    async def generate_task(self):
        """Generate the next key to press."""
        # Select a random category
        self.current_category = random.choice(list(self.KEY_CATEGORIES.keys()))

        # Select a random key from that category
        self.current_target_key = random.choice(self.KEY_CATEGORIES[self.current_category])

        # Record start time
        self.task_start_time = time.time()
        self.tasks_in_current_session += 1

    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a key event.

        Args:
            key_event: The key event

        Returns:
            True if task completed successfully
        """
        if self.current_target_key is None:
            return False

        # Check if the pressed key matches the target
        if key_event.matches(self.current_target_key):
            # Calculate reaction time
            reaction_time = time.time() - self.task_start_time

            # Calculate XP based on speed
            # Faster = more XP (0-5 bonus)
            speed_factor = max(0.5, min(2.0, 2.0 - (reaction_time / 2.0)))
            xp = calculate_xp_bonus(
                accuracy=100.0,  # Got it right
                speed_factor=speed_factor,
                streak_count=self.session.current_streak,
                base_xp=10
            )

            # Record success
            self.session.record_keystroke(correct=True)
            self.on_task_complete(xp)

            # Store reaction time in mode data
            reaction_times = self.session.get_mode_data('reaction_times', [])
            reaction_times.append(reaction_time)
            self.session.set_mode_data('reaction_times', reaction_times)

            return True

        # Wrong key pressed
        self.session.record_keystroke(correct=False)
        return False

    def get_display_text(self) -> str:
        """
        Get display text for the current state.

        Returns:
            Rich-formatted display text
        """
        lines = []

        lines.append("[bold cyan]⌨️  Comprehensive Keys Training[/]")
        lines.append("")
        lines.append(f"[yellow]Category:[/] {self.current_category.title() if self.current_category else 'N/A'}")
        lines.append("")

        if self.current_target_key:
            lines.append("[bold green]Press This Key:[/]")
            lines.append(f"[bold yellow on blue]   {self.current_target_key}   [/]")
        else:
            lines.append("[dim]Generating next key...[/]")

        lines.append("")
        lines.append(f"[cyan]Tasks Completed:[/] {self.session.tasks_completed}")
        lines.append(f"[cyan]Current Streak:[/] {self.session.current_streak}")
        lines.append(f"[cyan]Best Streak:[/] {self.session.best_streak}")
        lines.append(f"[cyan]Accuracy:[/] {self.session.calculate_accuracy():.1f}%")
        lines.append(f"[cyan]XP Earned:[/] {self.session.xp_earned:,}")

        # Show average reaction time if available
        reaction_times = self.session.get_mode_data('reaction_times', [])
        if reaction_times:
            avg_time = sum(reaction_times) / len(reaction_times)
            lines.append(f"[cyan]Avg Reaction Time:[/] {avg_time:.3f}s")

        lines.append("")
        lines.append(f"[dim]Press '{self.config.universal_exit_sequence}' to exit[/]")

        return "\n".join(lines)

    def calculate_score(self) -> int:
        """
        Calculate XP for current task.

        Returns:
            XP amount
        """
        # This is calculated in update() method
        return 0  # Placeholder

    def get_category_stats(self) -> dict:
        """
        Get statistics broken down by key category.

        Returns:
            Dictionary of category statistics
        """
        # This would track which categories the player practiced
        # For now, return empty dict
        return {}
