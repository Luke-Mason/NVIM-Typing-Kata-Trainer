"""Progress persistence management."""
import json
from pathlib import Path
from typing import Optional
from datetime import datetime

from .player import Player
from ..core.ranks import RankSystem
from ..utils.markdown_writer import generate_progress_report


class ProgressManager:
    """Manages loading and saving player progress."""

    def __init__(self, progress_dir: Path, rank_system: RankSystem):
        """
        Initialize the progress manager.

        Args:
            progress_dir: Directory to store progress files
            rank_system: RankSystem instance for rank calculations
        """
        self.progress_dir = progress_dir
        self.rank_system = rank_system
        self.player_file = progress_dir / "player_profile.json"
        self.markdown_file = progress_dir / "progress_report.md"

        # Ensure directory exists
        self.progress_dir.mkdir(parents=True, exist_ok=True)

    def load_player(self, default_name: str = "Player") -> Player:
        """
        Load player from JSON file or create new player.

        Args:
            default_name: Default name for new players

        Returns:
            Player instance
        """
        if self.player_file.exists():
            try:
                json_data = self.player_file.read_text(encoding='utf-8')
                player = Player.from_json(json_data)
                print(f"Loaded player: {player.name} (Rank {player.current_rank + 1})")
                return player
            except (json.JSONDecodeError, KeyError, ValueError) as e:
                print(f"Warning: Could not load player file: {e}")
                print("Creating new player profile...")

        # Create new player
        player = Player(
            name=default_name,
            created_at=datetime.now().isoformat(),
            last_played=datetime.now().isoformat()
        )
        print(f"Created new player: {player.name}")
        return player

    def save_player(self, player: Player, update_markdown: bool = True):
        """
        Save player to JSON file and optionally update markdown report.

        Args:
            player: Player instance to save
            update_markdown: Whether to regenerate the markdown report
        """
        # Update last played timestamp
        player.update_last_played()

        # Update rank based on XP
        new_rank = self.rank_system.get_rank_by_xp(player.current_xp)
        old_rank_id = player.current_rank
        player.current_rank = new_rank.id

        # Save to JSON
        json_data = player.to_json()
        self.player_file.write_text(json_data, encoding='utf-8')

        # Update markdown report
        if update_markdown:
            self.update_markdown_report(player)

        # Check for rank up
        if new_rank.id > old_rank_id:
            print(f"RANK UP! {new_rank.symbol} {new_rank.name}")
            return True

        return False

    def update_markdown_report(self, player: Player):
        """
        Generate and save markdown progress report.

        Args:
            player: Player instance
        """
        report = generate_progress_report(
            player=player,
            rank_system=self.rank_system,
            output_file=self.markdown_file
        )
        print(f"Progress report updated: {self.markdown_file}")

    def backup_progress(self) -> bool:
        """
        Create a backup of the current progress.

        Returns:
            True if backup was created, False otherwise
        """
        if not self.player_file.exists():
            return False

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = self.progress_dir / f"player_profile_backup_{timestamp}.json"

        try:
            content = self.player_file.read_text(encoding='utf-8')
            backup_file.write_text(content, encoding='utf-8')
            print(f"Backup created: {backup_file}")
            return True
        except Exception as e:
            print(f"Warning: Could not create backup: {e}")
            return False

    def reset_progress(self, player_name: str = "Player") -> Player:
        """
        Reset player progress (creates backup first).

        Args:
            player_name: Name for the new player

        Returns:
            New Player instance
        """
        # Create backup if progress exists
        if self.player_file.exists():
            self.backup_progress()

        # Create new player
        player = Player(
            name=player_name,
            created_at=datetime.now().isoformat(),
            last_played=datetime.now().isoformat()
        )

        # Save the new player
        self.save_player(player)

        print(f"Progress reset. New player created: {player_name}")
        return player

    def get_progress_summary(self, player: Player) -> str:
        """
        Get a brief progress summary.

        Args:
            player: Player instance

        Returns:
            Formatted summary string
        """
        current_rank = self.rank_system.get_rank(player.current_rank)
        next_rank = self.rank_system.get_next_rank(player.current_rank)

        lines = []
        if current_rank:
            lines.append(f"{current_rank.symbol} {current_rank.name}")
            lines.append(f"Rank {player.current_rank + 1}/100")

        if next_rank:
            xp_needed = self.rank_system.xp_to_next_rank(player.current_xp, player.current_rank)
            progress = self.rank_system.progress_to_next_rank(player.current_xp, player.current_rank)
            lines.append(f"XP: {player.current_xp:,} / {next_rank.xp_required:,} ({progress:.1f}%)")
            lines.append(f"Next: {next_rank.symbol} {next_rank.name} ({xp_needed:,} XP needed)")
        else:
            lines.append(f"XP: {player.current_xp:,}")
            lines.append("MAX RANK!")

        return '\n'.join(lines)
