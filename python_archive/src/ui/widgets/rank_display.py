"""Rank display widget showing current rank and XP progress."""
from textual.app import ComposeResult
from textual.widgets import Static
from textual.containers import Vertical

from ...models.player import Player
from ...core.ranks import RankSystem
from ...utils.stats_calculator import create_progress_bar


class RankDisplay(Static):
    """Widget to display player's current rank and XP progress."""

    def __init__(self, player: Player, rank_system: RankSystem, **kwargs):
        """
        Initialize rank display.

        Args:
            player: Player instance
            rank_system: RankSystem instance
        """
        super().__init__(**kwargs)
        self.player = player
        self.rank_system = rank_system

    def render(self) -> str:
        """Render the rank display."""
        current_rank = self.rank_system.get_rank(self.player.current_rank)
        next_rank = self.rank_system.get_next_rank(self.player.current_rank)
        is_max = self.rank_system.is_max_rank(self.player.current_rank)

        lines = []

        if current_rank:
            lines.append(f"[bold cyan]{current_rank.symbol} {current_rank.name}[/]")
            lines.append(f"[dim]Rank {self.player.current_rank + 1}/100[/]")
            lines.append("")

        if not is_max and next_rank:
            progress = self.rank_system.progress_to_next_rank(
                self.player.current_xp,
                self.player.current_rank
            )
            xp_needed = self.rank_system.xp_to_next_rank(
                self.player.current_xp,
                self.player.current_rank
            )

            lines.append(f"[yellow]XP:[/] {self.player.current_xp:,} / {next_rank.xp_required:,}")

            # Create progress bar
            bar_width = 30
            filled = int(bar_width * (progress / 100))
            empty = bar_width - filled
            bar = "[green]" + "█" * filled + "[/]" + "[dim]░" * empty + "[/]"
            lines.append(bar)
            lines.append(f"[dim]{progress:.1f}% - {xp_needed:,} XP to next rank[/]")
        else:
            lines.append(f"[yellow]XP:[/] {self.player.current_xp:,}")
            lines.append("[bold green]MAX RANK ACHIEVED![/]")

        return "\n".join(lines)

    def update_display(self):
        """Refresh the display."""
        self.refresh()
