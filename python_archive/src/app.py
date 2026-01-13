"""Main Textual application for NVIM Typing Kata Trainer."""
from textual.app import App
from textual.binding import Binding

from .core.config import Config
from .core.ranks import RankSystem
from .core.constants import ExitSequenceDetector
from .models.player import Player
from .models.progress import ProgressManager
from .ui.screens.main_menu import MainMenuScreen
from .ui.screens.stats import StatsScreen
from .ui.screens.settings import SettingsScreen


class VimTrainerApp(App):
    """Main application for NVIM Typing Kata Trainer."""

    CSS = """
    Screen {
        background: $surface;
    }

    .notification {
        background: $primary;
        color: $text;
        padding: 1 2;
    }
    """

    TITLE = "NVIM Typing Kata Trainer"
    SUB_TITLE = "Master Vim Through Gamified Training"

    BINDINGS = [
        Binding("q", "quit", "Quit", show=True),
        Binding("ctrl+c", "quit", "Quit", show=False),
    ]

    SCREENS = {
        "main_menu": MainMenuScreen,
        "stats": StatsScreen,
        "settings": SettingsScreen,
    }

    def __init__(self, config: Config):
        """
        Initialize the application.

        Args:
            config: Application configuration
        """
        super().__init__()
        self.config = config

        # Ensure directories exist
        self.config.ensure_directories()

        # Initialize rank system
        self.rank_system = RankSystem()

        # Initialize progress manager
        self.progress_manager = ProgressManager(
            progress_dir=self.config.progress_dir,
            rank_system=self.rank_system
        )

        # Load or create player
        self.player = self.progress_manager.load_player()

        # Update player rank based on XP
        current_rank = self.rank_system.get_rank_by_xp(self.player.current_xp)
        self.player.current_rank = current_rank.id

        # Increment session count
        self.player.increment_sessions()

        # Exit sequence detector
        self.exit_detector = ExitSequenceDetector(
            sequence=self.config.universal_exit_sequence
        )

        print(f"\nWelcome, {self.player.name}!")
        print(f"Current Rank: {current_rank.symbol} {current_rank.name} ({self.player.current_rank + 1}/100)")
        print(f"Total XP: {self.player.current_xp:,}\n")

    def on_mount(self) -> None:
        """Called when app is mounted."""
        self.push_screen("main_menu")

    def action_quit(self) -> None:
        """Handle quit action."""
        self.save_and_exit()

    def save_and_exit(self):
        """Save progress and exit the application."""
        print("\nSaving progress...")

        # Save player progress
        ranked_up = self.progress_manager.save_player(self.player, update_markdown=True)

        if ranked_up:
            new_rank = self.rank_system.get_rank(self.player.current_rank)
            print(f"\n🎉 Congratulations! You ranked up to {new_rank.symbol} {new_rank.name}!")

        print(f"Progress saved to: {self.progress_manager.player_file}")
        print(f"Report saved to: {self.progress_manager.markdown_file}")
        print("\nThanks for training! See you next time.\n")

        self.exit()

    def show_notification(self, message: str, timeout: float = 3.0):
        """
        Show a notification message.

        Args:
            message: Message to display
            timeout: How long to show the message (seconds)
        """
        self.notify(message, timeout=timeout)

    def award_xp(self, amount: int, mode: str):
        """
        Award XP to the player.

        Args:
            amount: Amount of XP to award
            mode: Game mode that awarded the XP
        """
        old_rank = self.player.current_rank
        self.player.add_xp(amount)

        # Update rank
        new_rank_obj = self.rank_system.get_rank_by_xp(self.player.current_xp)
        self.player.current_rank = new_rank_obj.id

        # Show notification
        self.show_notification(f"+ {amount:,} XP earned!")

        # Check for rank up
        if new_rank_obj.id > old_rank:
            self.show_notification(
                f"RANK UP! {new_rank_obj.symbol} {new_rank_obj.name}",
                timeout=5.0
            )

        # Update mode stats
        mode_stats = self.player.get_mode_stats(mode)
        mode_stats.total_xp_earned += amount

    def get_mode_stats(self, mode: str):
        """
        Get statistics for a specific mode.

        Args:
            mode: Game mode name

        Returns:
            ModeStats for the mode
        """
        return self.player.get_mode_stats(mode)

    def on_unmount(self) -> None:
        """Called when app is unmounted."""
        # Final save on exit
        self.progress_manager.save_player(self.player, update_markdown=True)
