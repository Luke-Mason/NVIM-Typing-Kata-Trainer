"""Main menu screen for game mode selection."""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Static
from textual.containers import Container, Vertical
from textual import events


class MainMenuScreen(Screen):
    """Main menu screen - k9s style minimal TUI."""

    BINDINGS = [
        ("1", "launch_custom", "Custom Keybindings"),
        ("2", "launch_snake", "Snake Apple"),
        ("3", "launch_symbols", "Symbol Training"),
        ("4", "launch_coding", "Coding Lessons"),
        ("5", "launch_words", "Word Typing"),
        ("6", "launch_motions", "Vim Motions"),
        ("7", "launch_keys", "Comprehensive Keys"),
        ("s", "show_stats", "Stats"),
        ("c", "show_settings", "Settings"),
        ("q", "quit_app", "Quit"),
        ("?", "show_help", "Help"),
    ]

    CSS = """
    MainMenuScreen {
        background: $surface;
    }

    #header {
        height: 3;
        content-align: center middle;
        text-align: center;
        background: $primary;
        color: $text;
    }

    #status-bar {
        height: 3;
        padding: 0 2;
        background: $panel;
        color: $text;
    }

    #menu {
        height: auto;
        padding: 1 2;
    }

    .menu-item {
        height: 1;
        padding: 0 1;
    }

    .menu-item:hover {
        background: $accent;
    }

    #footer {
        dock: bottom;
        height: 1;
        background: $panel;
        color: $text-muted;
        padding: 0 2;
    }
    """

    def compose(self) -> ComposeResult:
        """Compose the minimal menu."""
        # Header
        yield Static("[bold]NVIM TYPING KATA TRAINER[/]", id="header")

        # Status bar with rank
        yield Static(self._get_status_bar(), id="status-bar")

        # Menu items
        yield Vertical(
            Static("[bold cyan]TRAINING MODES[/]", classes="menu-item"),
            Static("[dim]─────────────[/]", classes="menu-item"),
            Static("  [bold]1[/] 🎯 Custom Keybindings  [dim]YOUR Neovim/Vim Setup[/]", id="menu-1", classes="menu-item"),
            Static("  [bold]2[/] 🐍 Snake Apple         [dim]Navigate with hjkl, w, b[/]", id="menu-2", classes="menu-item"),
            Static("  [bold]3[/] 🔣 Symbol Training     [dim]Special characters[/]", id="menu-3", classes="menu-item"),
            Static("  [bold]4[/] 💻 Coding Lessons      [dim]Type code with AI[/]", id="menu-4", classes="menu-item"),
            Static("  [bold]5[/] 📝 Word Typing          [dim]Type words (WPM like monkeytype)[/]", id="menu-5", classes="menu-item"),
            Static("  [bold]6[/] ⚡ Vim Motions         [dim]Complex operations[/]", id="menu-6", classes="menu-item"),
            Static("  [bold]7[/] ⌨️  Comprehensive Keys  [dim]All keyboard keys[/]", id="menu-7", classes="menu-item"),
            Static("", classes="menu-item"),
            Static("[bold cyan]OPTIONS[/]", classes="menu-item"),
            Static("[dim]───────[/]", classes="menu-item"),
            Static("  [bold]s[/] 📊 Stats     [bold]c[/] ⚙️  Settings     [bold]q[/] Exit     [bold]?[/] Help", classes="menu-item"),
            id="menu"
        )

        # Footer
        yield Static("[dim]Press number keys to select mode | s=stats c=settings q=quit ?=help[/]", id="footer")

    def _get_status_bar(self) -> str:
        """Get status bar with rank and XP."""
        player = self.app.player
        rank = self.app.rank_system.get_rank(player.current_rank)
        next_rank = self.app.rank_system.get_rank(player.current_rank + 1)

        # Progress to next rank
        current_xp = player.current_xp
        rank_xp = rank.xp_required if rank else 0
        next_xp = next_rank.xp_required if next_rank else rank_xp

        progress = 0
        if next_xp > rank_xp:
            progress = int(((current_xp - rank_xp) / (next_xp - rank_xp)) * 20)
            progress = max(0, min(20, progress))

        progress_bar = "█" * progress + "░" * (20 - progress)

        return f"[bold]{rank.symbol} {rank.name}[/]  XP: [cyan]{current_xp:,}[/]  [{progress_bar}]  [dim]Next: {next_xp:,}[/]"

    def on_key(self, event: events.Key) -> None:
        """Handle key presses for menu items."""
        key = event.key

        # Map keys to menu items
        if key == "1":
            self.action_launch_custom()
        elif key == "2":
            self.action_launch_snake()
        elif key == "3":
            self.action_launch_symbols()
        elif key == "4":
            self.action_launch_coding()
        elif key == "5":
            self.action_launch_words()
        elif key == "6":
            self.action_launch_motions()
        elif key == "7":
            self.action_launch_keys()
        elif key == "s":
            self.action_show_stats()
        elif key == "c":
            self.action_show_settings()
        elif key == "q":
            self.action_quit_app()
        elif key == "?" or key == "h":
            self.action_show_help()

    def on_mount(self) -> None:
        """Update status bar on mount."""
        self.update_status()

    def update_status(self) -> None:
        """Update the status bar."""
        status_bar = self.query_one("#status-bar", Static)
        status_bar.update(self._get_status_bar())

    # Action methods for keyboard shortcuts
    def action_launch_custom(self) -> None:
        """Launch Custom Keybindings mode."""
        from ...game_modes.custom_keybindings import CustomKeybindingsMode
        from .game_screen import GameScreen

        mode = CustomKeybindingsMode(self.app.config, self.app.player)
        screen = GameScreen(mode)
        self.app.push_screen(screen)

    def action_launch_snake(self) -> None:
        """Launch Snake Apple mode."""
        from ...game_modes.snake_apple import SnakeAppleMode
        from .game_screen import GameScreen

        mode = SnakeAppleMode(self.app.config, self.app.player)
        screen = GameScreen(mode)
        self.app.push_screen(screen)

    def action_launch_symbols(self) -> None:
        """Launch Symbol Training mode."""
        from ...game_modes.symbol_training import SymbolTrainingMode
        from .game_screen import GameScreen

        mode = SymbolTrainingMode(self.app.config, self.app.player)
        screen = GameScreen(mode)
        self.app.push_screen(screen)

    def action_launch_coding(self) -> None:
        """Launch Coding Lessons mode."""
        from ...game_modes.coding_lessons import CodingLessonsMode
        from .game_screen import GameScreen

        mode = CodingLessonsMode(self.app.config, self.app.player)
        screen = GameScreen(mode)
        self.app.push_screen(screen)

    def action_launch_words(self) -> None:
        """Launch Word Typing mode."""
        from ...game_modes.word_typing import WordTypingMode
        from .game_screen import GameScreen

        mode = WordTypingMode(self.app.config, self.app.player)
        screen = GameScreen(mode)
        self.app.push_screen(screen)

    def action_launch_motions(self) -> None:
        """Launch Vim Motions mode."""
        from ...game_modes.vim_motions import VimMotionsMode
        from .game_screen import GameScreen

        mode = VimMotionsMode(self.app.config, self.app.player)
        screen = GameScreen(mode)
        self.app.push_screen(screen)

    def action_launch_keys(self) -> None:
        """Launch Comprehensive Keys mode."""
        from ...game_modes.comprehensive_keys import ComprehensiveKeysMode
        from .game_screen import GameScreen

        mode = ComprehensiveKeysMode(self.app.config, self.app.player)
        screen = GameScreen(mode)
        self.app.push_screen(screen)

    def action_show_stats(self) -> None:
        """Show stats screen."""
        self.app.push_screen("stats")

    def action_show_settings(self) -> None:
        """Show settings screen."""
        self.app.push_screen("settings")

    def action_quit_app(self) -> None:
        """Quit the application."""
        self.app.exit()

    def action_show_help(self) -> None:
        """Show help dialog."""
        help_text = """[bold]KEYBOARD SHORTCUTS[/]

[bold cyan]Training Modes:[/]
  [bold]1[/] - Custom Keybindings (YOUR setup)
  [bold]2[/] - Snake Apple (navigation)
  [bold]3[/] - Symbol Training
  [bold]4[/] - Coding Lessons (AI)
  [bold]5[/] - Word Typing (WPM Training)
  [bold]6[/] - Vim Motions (AI)
  [bold]7[/] - Comprehensive Keys

[bold cyan]Navigation:[/]
  [bold]s[/] - View Stats
  [bold]c[/] - Settings
  [bold]q[/] - Quit
  [bold]?[/] or [bold]h[/] - This help

[bold cyan]In-Game:[/]
  [bold]jk[/] (quickly) - Exit any mode
  [bold]Ctrl+C[/] - Force quit

[dim]Press any key to close[/]"""

        # Create help screen as a modal
        from textual.widgets import Label
        from textual.containers import Container

        class HelpScreen(Screen):
            """Help modal screen."""

            CSS = """
            HelpScreen {
                align: center middle;
            }

            #help-container {
                width: 60;
                height: auto;
                background: $panel;
                border: heavy $primary;
                padding: 2;
            }
            """

            def compose(self) -> ComposeResult:
                yield Container(
                    Label(help_text),
                    id="help-container"
                )

            def on_key(self, event: events.Key) -> None:
                self.app.pop_screen()

        self.app.push_screen(HelpScreen())
