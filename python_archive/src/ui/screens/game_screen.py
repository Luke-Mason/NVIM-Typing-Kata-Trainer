"""Generic game screen for hosting game modes."""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Header, Footer, Static
from textual.containers import Container

from ...game_modes.base_mode import BaseGameMode
from ...input.keyboard_handler import KeyboardHandler, KeyEvent


class GameScreen(Screen):
    """Screen for running a game mode."""

    CSS = """
    GameScreen {
        align: center middle;
    }

    #game-container {
        width: 80;
        height: auto;
        padding: 2;
        border: solid $primary;
        background: $surface;
    }

    #game-display {
        padding: 2;
        content-align: center middle;
        text-align: center;
    }
    """

    def __init__(self, game_mode: BaseGameMode, **kwargs):
        """
        Initialize game screen.

        Args:
            game_mode: The game mode to run
        """
        super().__init__(**kwargs)
        self.game_mode = game_mode
        self.keyboard_handler: KeyboardHandler | None = None
        self.is_exiting = False

    def compose(self) -> ComposeResult:
        """Compose the game screen."""
        yield Header()

        yield Container(
            Static(id="game-display"),
            id="game-container"
        )

        yield Footer()

    async def on_mount(self) -> None:
        """Called when screen is mounted."""
        # Start the game mode
        await self.game_mode.start()

        # Set up keyboard handler
        self.keyboard_handler = KeyboardHandler(self._on_key_event)
        self.keyboard_handler.start()

        # Initial display update
        self._update_display()

    async def on_unmount(self) -> None:
        """Called when screen is unmounted."""
        # Stop keyboard handler
        if self.keyboard_handler:
            self.keyboard_handler.stop()

        # End the game mode if not already ended
        if self.game_mode.is_running:
            await self.game_mode.end()

            # Update player stats
            self.game_mode.update_player_stats()

            # Award XP
            if self.game_mode.session.xp_earned > 0:
                self.app.award_xp(self.game_mode.session.xp_earned, self.game_mode.mode_name)

    def _on_key_event(self, key_event: KeyEvent):
        """
        Handle keyboard events.

        Args:
            key_event: The key event
        """
        if self.is_exiting:
            return

        # Check for exit sequence
        if key_event.char and self.app.exit_detector.check(key_event.char):
            self._exit_game()
            return

        # Pass to game mode
        self.call_later(self._process_key_event, key_event)

    async def _process_key_event(self, key_event: KeyEvent):
        """
        Process key event asynchronously.

        Args:
            key_event: The key event
        """
        # Update game mode
        task_completed = await self.game_mode.update(key_event)

        # If task completed, generate next task
        if task_completed:
            await self.game_mode.generate_task()

        # Update display
        self._update_display()

    def _update_display(self):
        """Update the game display."""
        display = self.query_one("#game-display", Static)
        display.update(self.game_mode.get_display_text())

    def _exit_game(self):
        """Exit the game mode."""
        if self.is_exiting:
            return

        self.is_exiting = True

        # Show session summary
        summary = self.game_mode.get_session_summary()
        self.app.show_notification("Session ended!", timeout=2.0)

        # Pop this screen
        self.app.pop_screen()
