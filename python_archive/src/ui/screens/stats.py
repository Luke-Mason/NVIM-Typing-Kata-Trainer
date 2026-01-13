"""Stats and progress screen."""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Header, Footer, Button, Static
from textual.containers import Container, Vertical, ScrollableContainer

from ...utils.stats_calculator import format_time


class StatsScreen(Screen):
    """Display player stats and progress."""

    CSS = """
    StatsScreen {
        align: center top;
    }

    #stats-container {
        width: 80;
        height: auto;
        padding: 2;
        margin: 1;
    }

    .stats-section {
        padding: 1;
        margin: 1;
        border: solid $primary;
        background: $surface;
    }

    Button {
        width: 30;
        margin: 1;
    }
    """

    def compose(self) -> ComposeResult:
        """Compose the stats screen."""
        yield Header()

        yield ScrollableContainer(
            Static("[bold cyan]Player Statistics & Progress[/]\n", id="title"),
            Static(self._get_overall_stats(), classes="stats-section"),
            Static(self._get_mode_stats(), classes="stats-section"),
            Button("← Back to Menu", id="back", variant="primary"),
            id="stats-container"
        )

        yield Footer()

    def _get_overall_stats(self) -> str:
        """Get overall player statistics."""
        player = self.app.player
        rank = self.app.rank_system.get_rank(player.current_rank)

        lines = []
        lines.append("[bold yellow]Overall Progress[/]")
        lines.append("")
        lines.append(f"[cyan]Player Name:[/] {player.name}")
        if rank:
            lines.append(f"[cyan]Current Rank:[/] {rank.symbol} {rank.name} ({player.current_rank + 1}/100)")
        lines.append(f"[cyan]Total XP:[/] {player.current_xp:,}")
        lines.append(f"[cyan]Total Sessions:[/] {player.total_sessions}")
        lines.append(f"[cyan]Total Playtime:[/] {format_time(player.total_playtime)}")
        lines.append(f"[cyan]Account Created:[/] {player.created_at[:10]}")
        lines.append(f"[cyan]Last Played:[/] {player.last_played[:10]}")

        return "\n".join(lines)

    def _get_mode_stats(self) -> str:
        """Get per-mode statistics."""
        player = self.app.player

        if not player.stats:
            return "[dim]No game mode statistics yet. Start playing to track your progress![/]"

        mode_names = {
            'snake_apple': '🐍 Snake Apple',
            'symbol_training': '🔣 Symbol Training',
            'coding_lessons': '💻 Coding Lessons',
            'word_training': '📝 Word Training',
            'vim_motions': '⚡ Vim Motions',
            'comprehensive_keys': '⌨️ Comprehensive Keys',
        }

        lines = []
        lines.append("[bold yellow]Game Mode Statistics[/]")
        lines.append("")

        for mode_key, stats in player.stats.items():
            mode_name = mode_names.get(mode_key, mode_key.replace('_', ' ').title())
            lines.append(f"[bold cyan]{mode_name}[/]")
            lines.append(f"  Tasks Completed: {stats.tasks_completed}")
            lines.append(f"  Average Accuracy: {stats.total_accuracy:.1f}%")
            lines.append(f"  Average Speed: {stats.average_speed:.2f}")
            lines.append(f"  Best Streak: {stats.best_streak}")
            lines.append(f"  Time Played: {format_time(stats.total_time_played)}")
            lines.append(f"  XP Earned: {stats.total_xp_earned:,}")
            lines.append("")

        return "\n".join(lines)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        if event.button.id == "back":
            self.app.pop_screen()
