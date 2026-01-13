"""Player data model for tracking progress and stats."""
from dataclasses import dataclass, field, asdict
from datetime import datetime
from typing import Dict, Any
import json


@dataclass
class ModeStats:
    """Statistics for a single game mode."""
    tasks_completed: int = 0
    total_accuracy: float = 0.0  # Average accuracy percentage
    average_speed: float = 0.0  # Speed metric (varies by mode)
    best_streak: int = 0
    total_time_played: int = 0  # Seconds
    total_xp_earned: int = 0

    # Mode-specific data
    extra_data: Dict[str, Any] = field(default_factory=dict)

    def update_accuracy(self, new_accuracy: float):
        """Update average accuracy with a new value."""
        if self.tasks_completed == 0:
            self.total_accuracy = new_accuracy
        else:
            # Calculate rolling average
            total = self.total_accuracy * (self.tasks_completed - 1) + new_accuracy
            self.total_accuracy = total / self.tasks_completed

    def update_speed(self, new_speed: float):
        """Update average speed with a new value."""
        if self.tasks_completed == 0:
            self.average_speed = new_speed
        else:
            # Calculate rolling average
            total = self.average_speed * (self.tasks_completed - 1) + new_speed
            self.average_speed = total / self.tasks_completed

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ModeStats':
        """Create from dictionary."""
        return cls(**data)


@dataclass
class Player:
    """Player profile with progression and statistics."""
    name: str
    current_xp: int = 0
    current_rank: int = 0  # Rank ID (0-99)

    # Stats per game mode
    stats: Dict[str, ModeStats] = field(default_factory=dict)

    # Timestamps
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    last_played: str = field(default_factory=lambda: datetime.now().isoformat())

    # Session tracking
    total_sessions: int = 0
    total_playtime: int = 0  # Total seconds played

    def add_xp(self, amount: int) -> bool:
        """
        Add XP to the player.

        Args:
            amount: XP to add

        Returns:
            True if player ranked up, False otherwise
        """
        old_rank = self.current_rank
        self.current_xp += amount

        # Rank up will be handled by the rank system
        # This just returns whether the XP changed significantly
        return old_rank != self.current_rank

    def get_mode_stats(self, mode_name: str) -> ModeStats:
        """
        Get stats for a specific mode (creates if doesn't exist).

        Args:
            mode_name: Name of the game mode

        Returns:
            ModeStats for that mode
        """
        if mode_name not in self.stats:
            self.stats[mode_name] = ModeStats()
        return self.stats[mode_name]

    def update_last_played(self):
        """Update the last played timestamp."""
        self.last_played = datetime.now().isoformat()

    def increment_sessions(self):
        """Increment total session count."""
        self.total_sessions += 1

    def add_playtime(self, seconds: int):
        """Add to total playtime."""
        self.total_playtime += seconds

    def to_dict(self) -> Dict[str, Any]:
        """Convert player to dictionary."""
        data = asdict(self)
        # Convert ModeStats to dict
        data['stats'] = {mode: stats.to_dict() for mode, stats in self.stats.items()}
        return data

    def to_json(self) -> str:
        """Convert player to JSON string."""
        return json.dumps(self.to_dict(), indent=2)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Player':
        """Create player from dictionary."""
        # Handle stats conversion
        if 'stats' in data:
            data['stats'] = {
                mode: ModeStats.from_dict(stats_data)
                for mode, stats_data in data['stats'].items()
            }
        return cls(**data)

    @classmethod
    def from_json(cls, json_str: str) -> 'Player':
        """Create player from JSON string."""
        data = json.loads(json_str)
        return cls.from_dict(data)

    def __str__(self) -> str:
        """String representation."""
        return f"Player({self.name}, Rank {self.current_rank}, XP {self.current_xp})"
