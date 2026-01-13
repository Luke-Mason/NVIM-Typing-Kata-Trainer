"""Settings screen for configuration."""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Header, Footer, Button, Static
from textual.containers import Container, Vertical, ScrollableContainer

from ...core.constants import (
    AI_FEEDBACK_AFTER_EACH,
    AI_FEEDBACK_END_SESSION,
    AI_FEEDBACK_NONE
)


class SettingsScreen(Screen):
    """Settings and configuration screen."""

    CSS = """
    SettingsScreen {
        align: center top;
    }

    #settings-container {
        width: 80;
        height: auto;
        padding: 2;
        margin: 1;
    }

    .setting-section {
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
        """Compose the settings screen."""
        yield Header()

        yield ScrollableContainer(
            Static("[bold cyan]Settings & Configuration[/]\n", id="title"),
            Static(self._get_current_settings(), classes="setting-section"),
            Static(self._get_vimrc_info(), classes="setting-section"),
            Static(self._get_help_info(), classes="setting-section"),
            Button("← Back to Menu", id="back", variant="primary"),
            id="settings-container"
        )

        yield Footer()

    def _get_current_settings(self) -> str:
        """Get current settings display."""
        config = self.app.config

        lines = []
        lines.append("[bold yellow]Current Settings[/]")
        lines.append("")
        lines.append(f"[cyan]Universal Exit Sequence:[/] {config.universal_exit_sequence}")
        lines.append(f"[cyan]AI Feedback Timing:[/] {config.ai_feedback_timing}")
        lines.append(f"[cyan]Theme:[/] {config.theme}")
        lines.append(f"[cyan]Progress Directory:[/] {config.progress_dir}")
        lines.append("")
        lines.append("[dim]To change settings, edit your .env file and restart the application.[/]")

        return "\n".join(lines)

    def _get_vimrc_info(self) -> str:
        """Get vimrc configuration info."""
        config = self.app.config

        lines = []
        lines.append("[bold yellow]Vimrc Configuration[/]")
        lines.append("")

        if config.vimrc_path:
            lines.append(f"[cyan]Active Vimrc:[/] {config.vimrc_path}")
            lines.append("[green]✓ Vimrc detected and loaded[/]")
        else:
            lines.append("[yellow]⚠ No vimrc detected[/]")
            lines.append("")
            lines.append("[dim]To specify a custom vimrc path, add to your .env file:[/]")
            lines.append("[dim]VIMRC_PATH=C:\\path\\to\\your\\_vimrc[/]")

        if config.detected_vimrc_paths:
            lines.append("")
            lines.append("[cyan]Detected vimrc files:[/]")
            for path in config.detected_vimrc_paths:
                lines.append(f"  • {path}")

        return "\n".join(lines)

    def _get_help_info(self) -> str:
        """Get help information."""
        lines = []
        lines.append("[bold yellow]AI Feedback Options[/]")
        lines.append("")
        lines.append(f"[cyan]{AI_FEEDBACK_AFTER_EACH}:[/] Get immediate feedback after each vim motion task")
        lines.append(f"[cyan]{AI_FEEDBACK_END_SESSION}:[/] Get batched feedback at the end of your session")
        lines.append(f"[cyan]{AI_FEEDBACK_NONE}:[/] Disable AI keystroke analysis (lessons still work)")
        lines.append("")
        lines.append("[bold yellow]Exit Sequence[/]")
        lines.append("")
        lines.append(f"Press '{self.app.config.universal_exit_sequence}' quickly (within 0.5s) to exit any game mode.")
        lines.append("This works in all game modes to prevent getting stuck.")

        return "\n".join(lines)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        if event.button.id == "back":
            self.app.pop_screen()
