"""Tests for player model."""
import pytest
import json
from datetime import datetime

from src.models.player import Player, ModeStats


class TestModeStats:
    """Tests for ModeStats class."""

    def test_mode_stats_creation(self):
        """Test creating mode stats."""
        stats = ModeStats()
        assert stats.tasks_completed == 0
        assert stats.total_accuracy == 0.0
        assert stats.average_speed == 0.0
        assert stats.best_streak == 0
        assert stats.total_time_played == 0
        assert stats.total_xp_earned == 0

    def test_update_accuracy_first_task(self):
        """Test updating accuracy for first task."""
        stats = ModeStats()
        stats.tasks_completed = 1
        stats.update_accuracy(95.5)
        assert stats.total_accuracy == 95.5

    def test_update_accuracy_multiple_tasks(self):
        """Test calculating rolling average accuracy."""
        stats = ModeStats()

        stats.tasks_completed = 1
        stats.update_accuracy(100.0)
        assert stats.total_accuracy == 100.0

        stats.tasks_completed = 2
        stats.update_accuracy(80.0)
        assert stats.total_accuracy == 90.0  # (100 + 80) / 2

        stats.tasks_completed = 3
        stats.update_accuracy(90.0)
        assert abs(stats.total_accuracy - 90.0) < 0.01  # (100 + 80 + 90) / 3

    def test_update_speed_first_task(self):
        """Test updating speed for first task."""
        stats = ModeStats()
        stats.tasks_completed = 1
        stats.update_speed(2.5)
        assert stats.average_speed == 2.5

    def test_update_speed_multiple_tasks(self):
        """Test calculating rolling average speed."""
        stats = ModeStats()

        stats.tasks_completed = 1
        stats.update_speed(2.0)

        stats.tasks_completed = 2
        stats.update_speed(3.0)

        assert abs(stats.average_speed - 2.5) < 0.01  # (2.0 + 3.0) / 2

    def test_to_dict(self):
        """Test converting stats to dictionary."""
        stats = ModeStats(
            tasks_completed=10,
            total_accuracy=95.0,
            average_speed=2.5,
            best_streak=5,
            total_time_played=300,
            total_xp_earned=1000
        )

        data = stats.to_dict()
        assert data["tasks_completed"] == 10
        assert data["total_accuracy"] == 95.0
        assert data["best_streak"] == 5

    def test_from_dict(self):
        """Test creating stats from dictionary."""
        data = {
            "tasks_completed": 20,
            "total_accuracy": 88.5,
            "average_speed": 3.2,
            "best_streak": 8,
            "total_time_played": 600,
            "total_xp_earned": 2000,
            "extra_data": {}
        }

        stats = ModeStats.from_dict(data)
        assert stats.tasks_completed == 20
        assert stats.total_accuracy == 88.5
        assert stats.best_streak == 8


class TestPlayer:
    """Tests for Player class."""

    def test_player_creation(self):
        """Test creating a player."""
        player = Player(name="TestPlayer")
        assert player.name == "TestPlayer"
        assert player.current_xp == 0
        assert player.current_rank == 0
        assert len(player.stats) == 0

    def test_player_with_initial_values(self):
        """Test creating player with initial values."""
        player = Player(
            name="Player1",
            current_xp=1000,
            current_rank=5
        )

        assert player.name == "Player1"
        assert player.current_xp == 1000
        assert player.current_rank == 5

    def test_add_xp(self):
        """Test adding XP to player."""
        player = Player(name="TestPlayer")

        player.add_xp(100)
        assert player.current_xp == 100

        player.add_xp(50)
        assert player.current_xp == 150

    def test_add_xp_negative(self):
        """Test that negative XP can be added (for penalties)."""
        player = Player(name="TestPlayer", current_xp=100)

        player.add_xp(-50)
        assert player.current_xp == 50

    def test_get_mode_stats_creates_if_missing(self):
        """Test that getting mode stats creates them if they don't exist."""
        player = Player(name="TestPlayer")

        stats = player.get_mode_stats("test_mode")
        assert isinstance(stats, ModeStats)
        assert "test_mode" in player.stats

    def test_get_mode_stats_returns_existing(self):
        """Test that getting mode stats returns existing stats."""
        player = Player(name="TestPlayer")

        stats1 = player.get_mode_stats("test_mode")
        stats1.tasks_completed = 10

        stats2 = player.get_mode_stats("test_mode")
        assert stats2.tasks_completed == 10
        assert stats1 is stats2  # Same object

    def test_update_last_played(self):
        """Test updating last played timestamp."""
        player = Player(name="TestPlayer")

        old_timestamp = player.last_played
        player.update_last_played()

        # Timestamp should have changed
        assert player.last_played != old_timestamp

    def test_increment_sessions(self):
        """Test incrementing session count."""
        player = Player(name="TestPlayer")

        assert player.total_sessions == 0

        player.increment_sessions()
        assert player.total_sessions == 1

        player.increment_sessions()
        assert player.total_sessions == 2

    def test_add_playtime(self):
        """Test adding playtime."""
        player = Player(name="TestPlayer")

        assert player.total_playtime == 0

        player.add_playtime(60)
        assert player.total_playtime == 60

        player.add_playtime(120)
        assert player.total_playtime == 180

    def test_to_dict(self):
        """Test converting player to dictionary."""
        player = Player(name="TestPlayer", current_xp=500, current_rank=3)
        player.total_sessions = 5

        data = player.to_dict()
        assert data["name"] == "TestPlayer"
        assert data["current_xp"] == 500
        assert data["current_rank"] == 3
        assert data["total_sessions"] == 5

    def test_to_json(self):
        """Test converting player to JSON."""
        player = Player(name="TestPlayer", current_xp=1000)

        json_str = player.to_json()
        data = json.loads(json_str)

        assert data["name"] == "TestPlayer"
        assert data["current_xp"] == 1000

    def test_from_dict(self):
        """Test creating player from dictionary."""
        data = {
            "name": "LoadedPlayer",
            "current_xp": 2000,
            "current_rank": 10,
            "stats": {},
            "created_at": "2024-01-01T00:00:00",
            "last_played": "2024-01-02T00:00:00",
            "total_sessions": 3,
            "total_playtime": 600
        }

        player = Player.from_dict(data)
        assert player.name == "LoadedPlayer"
        assert player.current_xp == 2000
        assert player.current_rank == 10
        assert player.total_sessions == 3

    def test_from_json(self):
        """Test creating player from JSON."""
        json_str = '{"name": "JSONPlayer", "current_xp": 500, "current_rank": 2, "stats": {}, "created_at": "2024-01-01T00:00:00", "last_played": "2024-01-01T00:00:00", "total_sessions": 0, "total_playtime": 0}'

        player = Player.from_json(json_str)
        assert player.name == "JSONPlayer"
        assert player.current_xp == 500
        assert player.current_rank == 2

    def test_player_with_mode_stats(self):
        """Test player with mode stats serialization."""
        player = Player(name="TestPlayer")

        # Add some stats
        stats = player.get_mode_stats("test_mode")
        stats.tasks_completed = 5
        stats.total_accuracy = 90.0

        # Convert to dict and back
        data = player.to_dict()
        loaded_player = Player.from_dict(data)

        # Verify stats were preserved
        loaded_stats = loaded_player.get_mode_stats("test_mode")
        assert loaded_stats.tasks_completed == 5
        assert loaded_stats.total_accuracy == 90.0

    def test_str_representation(self):
        """Test string representation of player."""
        player = Player(name="TestPlayer", current_xp=1500, current_rank=8)

        str_repr = str(player)
        assert "TestPlayer" in str_repr
        assert "1500" in str_repr
        assert "8" in str_repr
