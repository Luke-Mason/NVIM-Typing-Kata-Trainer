"""Base game mode interface."""
from abc import ABC, abstractmethod
from typing import Optional
from datetime import datetime

from ..core.config import Config
from ..models.player import Player
from ..models.session import GameSession
from ..input.keyboard_handler import KeyEvent


class BaseGameMode(ABC):
    """Abstract base class for all game modes."""

    def __init__(self, config: Config, player: Player, mode_name: str):
        """
        Initialize base game mode.

        Args:
            config: Application configuration
            player: Player instance
            mode_name: Name of this game mode
        """
        self.config = config
        self.player = player
        self.mode_name = mode_name
        self.session = GameSession(mode=mode_name)
        self.is_running = False

    @abstractmethod
    async def setup(self):
        """
        Initialize the game mode.
        Called once when the mode starts.
        """
        pass

    @abstractmethod
    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a key event and update game state.

        Args:
            key_event: The key event to process

        Returns:
            True if task was completed, False otherwise
        """
        pass

    @abstractmethod
    async def generate_task(self):
        """
        Generate the next task or challenge.
        Called after setup and after each completed task.
        """
        pass

    @abstractmethod
    def get_display_text(self) -> str:
        """
        Get the text to display to the user.

        Returns:
            Rich-formatted text to display
        """
        pass

    @abstractmethod
    def calculate_score(self) -> int:
        """
        Calculate XP earned for the current task.

        Returns:
            XP amount to award
        """
        pass

    async def start(self):
        """Start the game mode session."""
        self.session.start()
        self.is_running = True
        await self.setup()
        await self.generate_task()

    async def end(self):
        """End the game mode session."""
        self.session.end()
        self.is_running = False

    def get_session_summary(self) -> str:
        """
        Get a summary of the current session.

        Returns:
            Formatted session summary
        """
        duration = self.session.duration_seconds()
        accuracy = self.session.calculate_accuracy()

        lines = []
        lines.append(f"[bold cyan]Session Complete: {self.mode_name}[/]")
        lines.append("")
        lines.append(f"[yellow]Tasks Completed:[/] {self.session.tasks_completed}")
        lines.append(f"[yellow]Accuracy:[/] {accuracy:.1f}%")
        lines.append(f"[yellow]Best Streak:[/] {self.session.best_streak}")
        lines.append(f"[yellow]XP Earned:[/] +{self.session.xp_earned:,}")
        lines.append(f"[yellow]Duration:[/] {int(duration)}s")

        return "\n".join(lines)

    def update_player_stats(self):
        """Update player statistics with session data."""
        mode_stats = self.player.get_mode_stats(self.mode_name)

        # Update task count
        mode_stats.tasks_completed += self.session.tasks_completed

        # Update accuracy
        if self.session.tasks_completed > 0:
            session_accuracy = self.session.calculate_accuracy()
            mode_stats.update_accuracy(session_accuracy)

        # Update best streak
        if self.session.best_streak > mode_stats.best_streak:
            mode_stats.best_streak = self.session.best_streak

        # Update time played
        mode_stats.total_time_played += int(self.session.duration_seconds())

        # Update XP
        mode_stats.total_xp_earned += self.session.xp_earned

    def on_task_complete(self, xp: int):
        """
        Called when a task is completed.

        Args:
            xp: XP to award for this task
        """
        self.session.add_task_completion(xp)
