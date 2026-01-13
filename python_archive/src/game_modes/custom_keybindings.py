"""Custom Keybindings Mode - Practice YOUR Neovim/Vim keybindings."""
import random
import time
from typing import List, Optional, Dict, Any

from .base_mode import BaseGameMode
from ..core.config import Config
from ..models.player import Player
from ..input.keyboard_handler import KeyEvent
from ..utils.stats_calculator import calculate_xp_bonus
from ..core.nvim_parser import NvimConfigParser, NvimKeymap
from ..core.vimrc_parser import VimrcParser


class CustomKeybindingsMode(BaseGameMode):
    """Game mode for practicing user's custom Neovim/Vim keybindings."""

    def __init__(self, config: Config, player: Player):
        """
        Initialize Custom Keybindings mode.

        Args:
            config: Application configuration
            player: Player instance
        """
        super().__init__(config, player, mode_name="custom_keybindings")

        # Parse configurations
        self.nvim_parser = NvimConfigParser()
        self.vimrc_parser = VimrcParser(config.vimrc_path)

        self.custom_keymaps: List[NvimKeymap] = []
        self.current_keymap: Optional[NvimKeymap] = None
        self.typed_sequence: str = ""
        self.task_start_time: float = 0
        self.hint_shown: bool = False

        # Load configurations
        self._load_configurations()

    def _load_configurations(self):
        """Load Neovim and/or Vimrc configurations."""
        loaded_any = False

        # Try to parse Neovim config
        if self.nvim_parser.parse():
            training_keymaps = self.nvim_parser.get_custom_training_keymaps()
            self.custom_keymaps.extend(training_keymaps)
            loaded_any = True

        # Try to parse vimrc
        if self.config.vimrc_path and self.vimrc_parser.parse():
            # Convert VimrcParser mappings to NvimKeymap format
            for mapping in self.vimrc_parser.get_mappings():
                keymap = NvimKeymap(
                    mode=mapping.mode.split(',')[0],  # Take first mode
                    lhs=mapping.from_keys,
                    rhs=mapping.to_keys,
                    description=mapping.comment,
                    source_file='vimrc'
                )
                self.custom_keymaps.append(keymap)
            loaded_any = True

        if not loaded_any:
            # Use fallback keymaps
            self.custom_keymaps = self._get_fallback_keymaps()

    def _get_fallback_keymaps(self) -> List[NvimKeymap]:
        """Get common vim keymaps as fallback."""
        return [
            NvimKeymap('n', '<leader>w', ':w<CR>', 'Save file', source_file='fallback'),
            NvimKeymap('n', '<leader>q', ':q<CR>', 'Quit', source_file='fallback'),
            NvimKeymap('n', '<leader>x', ':x<CR>', 'Save and quit', source_file='fallback'),
            NvimKeymap('n', '<leader>e', ':Explore<CR>', 'File explorer', source_file='fallback'),
            NvimKeymap('n', 'gg', 'gg', 'Go to top', source_file='fallback'),
            NvimKeymap('n', 'G', 'G', 'Go to bottom', source_file='fallback'),
            NvimKeymap('n', 'dd', 'dd', 'Delete line', source_file='fallback'),
            NvimKeymap('n', 'yy', 'yy', 'Yank line', source_file='fallback'),
            NvimKeymap('n', 'p', 'p', 'Paste', source_file='fallback'),
            NvimKeymap('n', 'u', 'u', 'Undo', source_file='fallback'),
            NvimKeymap('n', '<C-r>', '<C-r>', 'Redo', source_file='fallback'),
        ]

    async def setup(self):
        """Initialize the game mode."""
        if not self.custom_keymaps:
            self._load_configurations()

    async def generate_task(self):
        """Generate a new keybinding to practice."""
        if not self.custom_keymaps:
            return

        # Select a random keybinding
        self.current_keymap = random.choice(self.custom_keymaps)
        self.typed_sequence = ""
        self.task_start_time = time.time()
        self.hint_shown = False

    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a key event.

        Args:
            key_event: The key event

        Returns:
            True if task completed successfully
        """
        if not self.current_keymap:
            return False

        # Ignore modifier keys when pressed alone
        if key_event.key_name in ['Shift', 'Ctrl', 'Alt', 'Cmd'] and not key_event.char:
            return False

        # Get the key representation
        key = self._format_key(key_event)
        self.typed_sequence += key

        # Get the target sequence (parse the lhs)
        target_sequence = self._parse_lhs(self.current_keymap.lhs)

        # Check if sequence matches so far
        if target_sequence.startswith(self.typed_sequence):
            # Correct so far
            if self.typed_sequence == target_sequence:
                # Complete!
                reaction_time = time.time() - self.task_start_time

                # Calculate XP
                complexity_bonus = min(2.0, len(target_sequence) / 3.0)
                speed_factor = max(0.5, min(2.0, 2.0 - (reaction_time / 5.0)))

                xp = calculate_xp_bonus(
                    accuracy=100.0,
                    speed_factor=speed_factor * complexity_bonus,
                    streak_count=self.session.current_streak,
                    base_xp=25  # Higher base XP for custom keybindings
                )

                # Record success
                self.session.record_keystroke(correct=True)
                self.on_task_complete(xp)

                # Store stats
                stats = self.session.get_mode_data('custom_kb_stats', {
                    'keybindings_practiced': [],
                    'reaction_times': []
                })
                stats['keybindings_practiced'].append(self.current_keymap.lhs)
                stats['reaction_times'].append(reaction_time)
                self.session.set_mode_data('custom_kb_stats', stats)

                return True

            # Correct so far, but not complete
            return False

        # Wrong sequence, reset
        self.session.record_keystroke(correct=False)
        self.typed_sequence = ""
        return False

    def _format_key(self, key_event: KeyEvent) -> str:
        """Format a key event into a string representation."""
        key = ""

        # Handle modifiers
        if 'ctrl' in key_event.modifiers:
            key += "<C-"
        if 'alt' in key_event.modifiers:
            key += "<A-"
        if 'shift' in key_event.modifiers and key_event.key_name not in ['Space', 'Enter', 'Tab']:
            key += "<S-"

        # Handle special keys
        if key_event.key_name == 'Space':
            key += "<Space>"
        elif key_event.key_name == 'Enter':
            key += "<CR>"
        elif key_event.key_name == 'Escape':
            key += "<Esc>"
        elif key_event.key_name == 'Tab':
            key += "<Tab>"
        elif key_event.char:
            key += key_event.char
        else:
            key += f"<{key_event.key_name}>"

        # Close modifier brackets
        if key.startswith("<C-") or key.startswith("<A-") or key.startswith("<S-"):
            if not key.endswith(">"):
                key += ">"

        return key

    def _parse_lhs(self, lhs: str) -> str:
        """
        Parse left-hand side keymap into a sequence.

        Args:
            lhs: Left-hand side string (e.g., '<leader>ff')

        Returns:
            Parsed sequence
        """
        # Replace leader with actual key
        leader = self.nvim_parser.get_leader_key()
        lhs = lhs.replace('<leader>', leader)
        lhs = lhs.replace(f'<leader:{leader}>', leader)

        localleader = self.nvim_parser.get_localleader_key()
        lhs = lhs.replace('<localleader>', localleader)
        lhs = lhs.replace(f'<localleader:{localleader}>', localleader)

        return lhs

    def get_display_text(self) -> str:
        """
        Get display text for the current state.

        Returns:
            Rich-formatted display text
        """
        lines = []

        lines.append("[bold cyan]🎯 Custom Keybindings - YOUR Setup![/]")
        lines.append("")

        # Show config status
        nvim_count = len(self.nvim_parser.get_keymaps())
        vimrc_count = len(self.vimrc_parser.get_mappings()) if self.config.vimrc_path else 0

        if nvim_count > 0:
            lines.append(f"[green]✓[/] Neovim config loaded: {nvim_count} keymaps")
        if vimrc_count > 0:
            lines.append(f"[green]✓[/] Vimrc loaded: {vimrc_count} mappings")

        if nvim_count == 0 and vimrc_count == 0:
            lines.append("[yellow]⚠[/] Using fallback keymaps (no custom config found)")

        lines.append("")

        if self.current_keymap:
            # Show the keybinding to practice
            lines.append("[bold yellow]Press this keybinding:[/]")
            lines.append("")

            # Show the keys with highlighting
            target = self._parse_lhs(self.current_keymap.lhs)
            if self.typed_sequence:
                correct_part = target[:len(self.typed_sequence)]
                remaining = target[len(self.typed_sequence):]
                lines.append(f"  [green]{correct_part}[/][bold yellow on blue]{remaining}[/]")
            else:
                lines.append(f"  [bold yellow on blue]{target}[/]")

            lines.append("")

            # Show description
            if self.current_keymap.description:
                lines.append(f"[dim italic]What it does: {self.current_keymap.description}[/]")
            else:
                lines.append(f"[dim italic]Maps to: {self.current_keymap.rhs}[/]")

            # Show source
            if self.current_keymap.source_file and 'fallback' not in self.current_keymap.source_file:
                filename = self.current_keymap.source_file.split('/')[-1]
                lines.append(f"[dim]From: {filename}[/]")

            if self.current_keymap.plugin:
                lines.append(f"[dim]Plugin: {self.current_keymap.plugin}[/]")

        lines.append("")
        lines.append(f"[cyan]Tasks Completed:[/] {self.session.tasks_completed}")
        lines.append(f"[cyan]Current Streak:[/] {self.session.current_streak}")
        lines.append(f"[cyan]XP Earned:[/] {self.session.xp_earned:,}")

        # Show unique keybindings practiced
        stats = self.session.get_mode_data('custom_kb_stats', {})
        if 'keybindings_practiced' in stats:
            unique_kb = len(set(stats['keybindings_practiced']))
            lines.append(f"[cyan]Unique Keybindings:[/] {unique_kb}")

        lines.append("")
        lines.append(f"[dim]Practice your custom setup | '{self.config.universal_exit_sequence}' to exit[/]")

        return "\n".join(lines)

    def calculate_score(self) -> int:
        """Calculate XP for current task."""
        return 0  # Calculated in update()

    def get_config_summary(self) -> str:
        """
        Get a summary of loaded configurations.

        Returns:
            Configuration summary
        """
        lines = []

        # Neovim summary
        nvim_stats = self.nvim_parser.get_statistics()
        if nvim_stats['total_keymaps'] > 0:
            lines.append(f"Neovim Configuration:")
            lines.append(f"  Leader: {self.nvim_parser.get_leader_key()}")
            lines.append(f"  Total keymaps: {nvim_stats['total_keymaps']}")
            lines.append(f"  Plugins: {nvim_stats['total_plugins']}")
            lines.append("")

        # Vimrc summary
        if self.config.vimrc_path:
            vimrc_stats = self.vimrc_parser.get_statistics()
            if vimrc_stats['total_mappings'] > 0:
                lines.append(f"Vimrc Configuration:")
                lines.append(f"  Total mappings: {vimrc_stats['total_mappings']}")
                lines.append("")

        if not lines:
            lines.append("No custom configurations found")

        return "\n".join(lines)

    def get_all_keymaps(self) -> List[NvimKeymap]:
        """Get all loaded keymaps."""
        return self.custom_keymaps

    def has_custom_config(self) -> bool:
        """Check if any custom configuration was loaded."""
        return len(self.custom_keymaps) > 0 and any(
            km.source_file and 'fallback' not in km.source_file
            for km in self.custom_keymaps
        )
