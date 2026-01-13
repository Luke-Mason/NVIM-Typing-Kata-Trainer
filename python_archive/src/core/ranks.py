"""Rank system for player progression."""
import json
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass


@dataclass
class Rank:
    """Represents a military rank in the progression system."""
    id: int
    name: str
    symbol: str
    xp_required: int

    @classmethod
    def from_dict(cls, data: Dict) -> 'Rank':
        """Create a Rank from a dictionary."""
        return cls(
            id=data['id'],
            name=data['name'],
            symbol=data['symbol'],
            xp_required=data['xp_required']
        )

    def to_dict(self) -> Dict:
        """Convert rank to dictionary."""
        return {
            'id': self.id,
            'name': self.name,
            'symbol': self.symbol,
            'xp_required': self.xp_required
        }


class RankSystem:
    """Manages the rank system and progression."""

    def __init__(self, ranks_file: Optional[Path] = None):
        """
        Initialize the rank system.

        Args:
            ranks_file: Path to the ranks JSON file. If None, uses default.
        """
        if ranks_file is None:
            # Default to data/ranks/rank_definitions.json
            project_root = Path(__file__).parent.parent.parent
            ranks_file = project_root / "data" / "ranks" / "rank_definitions.json"

        self.ranks: List[Rank] = []
        self._load_ranks(ranks_file)

    def _load_ranks(self, ranks_file: Path):
        """Load ranks from JSON file."""
        try:
            with open(ranks_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.ranks = [Rank.from_dict(rank_data) for rank_data in data]
        except FileNotFoundError:
            raise FileNotFoundError(f"Ranks file not found: {ranks_file}")
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in ranks file: {e}")

    def get_rank(self, rank_id: int) -> Optional[Rank]:
        """Get a rank by its ID."""
        if 0 <= rank_id < len(self.ranks):
            return self.ranks[rank_id]
        return None

    def get_rank_by_xp(self, xp: int) -> Rank:
        """
        Get the appropriate rank for a given XP amount.

        Args:
            xp: The player's total XP

        Returns:
            The highest rank the player has achieved
        """
        current_rank = self.ranks[0]
        for rank in self.ranks:
            if xp >= rank.xp_required:
                current_rank = rank
            else:
                break
        return current_rank

    def get_next_rank(self, current_rank_id: int) -> Optional[Rank]:
        """Get the next rank after the current one."""
        next_id = current_rank_id + 1
        if next_id < len(self.ranks):
            return self.ranks[next_id]
        return None

    def xp_to_next_rank(self, current_xp: int, current_rank_id: int) -> int:
        """
        Calculate XP needed to reach the next rank.

        Args:
            current_xp: Player's current XP
            current_rank_id: Player's current rank ID

        Returns:
            XP needed for next rank (0 if at max rank)
        """
        next_rank = self.get_next_rank(current_rank_id)
        if next_rank is None:
            return 0
        return max(0, next_rank.xp_required - current_xp)

    def progress_to_next_rank(self, current_xp: int, current_rank_id: int) -> float:
        """
        Calculate progress towards next rank as a percentage (0-100).

        Args:
            current_xp: Player's current XP
            current_rank_id: Player's current rank ID

        Returns:
            Progress percentage (0-100)
        """
        current_rank = self.get_rank(current_rank_id)
        next_rank = self.get_next_rank(current_rank_id)

        if next_rank is None:
            return 100.0  # Max rank

        if current_rank is None:
            return 0.0

        xp_in_rank = current_xp - current_rank.xp_required
        xp_needed = next_rank.xp_required - current_rank.xp_required

        if xp_needed <= 0:
            return 100.0

        progress = (xp_in_rank / xp_needed) * 100
        return max(0.0, min(100.0, progress))

    def total_ranks(self) -> int:
        """Get the total number of ranks."""
        return len(self.ranks)

    def is_max_rank(self, rank_id: int) -> bool:
        """Check if the player is at max rank."""
        return rank_id >= len(self.ranks) - 1
