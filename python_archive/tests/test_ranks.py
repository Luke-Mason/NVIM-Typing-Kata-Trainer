"""Tests for the rank system."""
import pytest
from pathlib import Path

from src.core.ranks import Rank, RankSystem


class TestRank:
    """Tests for the Rank class."""

    def test_rank_creation(self):
        """Test creating a rank."""
        rank = Rank(id=0, name="Recruit", symbol="🎖️", xp_required=0)
        assert rank.id == 0
        assert rank.name == "Recruit"
        assert rank.symbol == "🎖️"
        assert rank.xp_required == 0

    def test_rank_from_dict(self):
        """Test creating rank from dictionary."""
        data = {"id": 1, "name": "Private", "symbol": "⚔️", "xp_required": 100}
        rank = Rank.from_dict(data)
        assert rank.id == 1
        assert rank.name == "Private"
        assert rank.xp_required == 100

    def test_rank_to_dict(self):
        """Test converting rank to dictionary."""
        rank = Rank(id=2, name="Corporal", symbol="🎯", xp_required= 500)
        data = rank.to_dict()
        assert data["id"] == 2
        assert data["name"] == "Corporal"
        assert data["symbol"] == "🎯"
        assert data["xp_required"] == 500


class TestRankSystem:
    """Tests for the RankSystem class."""

    @pytest.fixture
    def rank_system(self):
        """Create a rank system instance."""
        return RankSystem()

    def test_rank_system_loads_ranks(self, rank_system):
        """Test that rank system loads all ranks."""
        assert len(rank_system.ranks) == 100
        assert rank_system.total_ranks() == 100

    def test_rank_system_first_rank_is_recruit(self, rank_system):
        """Test that first rank is Recruit with 0 XP."""
        rank = rank_system.get_rank(0)
        assert rank is not None
        assert rank.name == "Recruit"
        assert rank.xp_required == 0

    def test_rank_system_last_rank_is_max(self, rank_system):
        """Test that last rank is Ultimate Vim God."""
        rank = rank_system.get_rank(99)
        assert rank is not None
        assert "Vim God" in rank.name

    def test_get_rank_by_id(self, rank_system):
        """Test getting rank by ID."""
        rank = rank_system.get_rank(5)
        assert rank is not None
        assert rank.id == 5

    def test_get_rank_invalid_id(self, rank_system):
        """Test getting rank with invalid ID."""
        assert rank_system.get_rank(-1) is None
        assert rank_system.get_rank(100) is None

    def test_get_rank_by_xp_zero(self, rank_system):
        """Test getting rank for 0 XP."""
        rank = rank_system.get_rank_by_xp(0)
        assert rank.id == 0
        assert rank.name == "Recruit"

    def test_get_rank_by_xp_progression(self, rank_system):
        """Test rank progression with increasing XP."""
        # Just above first rank threshold
        rank1 = rank_system.get_rank_by_xp(100)
        assert rank1.id >= 1

        # Mid-level XP
        rank2 = rank_system.get_rank_by_xp(10000)
        assert rank2.id > rank1.id

        # Very high XP
        rank3 = rank_system.get_rank_by_xp(500000)
        assert rank3.id > rank2.id
        assert rank3.id == 99  # Should be max rank

    def test_get_next_rank(self, rank_system):
        """Test getting next rank."""
        next_rank = rank_system.get_next_rank(0)
        assert next_rank is not None
        assert next_rank.id == 1

    def test_get_next_rank_at_max(self, rank_system):
        """Test getting next rank when at max rank."""
        next_rank = rank_system.get_next_rank(99)
        assert next_rank is None

    def test_xp_to_next_rank(self, rank_system):
        """Test calculating XP needed for next rank."""
        current_xp = 0
        current_rank = 0
        xp_needed = rank_system.xp_to_next_rank(current_xp, current_rank)

        next_rank = rank_system.get_next_rank(current_rank)
        assert xp_needed == next_rank.xp_required

    def test_xp_to_next_rank_at_max(self, rank_system):
        """Test XP to next rank when at max rank."""
        xp_needed = rank_system.xp_to_next_rank(1000000, 99)
        assert xp_needed == 0

    def test_progress_to_next_rank_zero_xp(self, rank_system):
        """Test progress calculation with 0 XP."""
        progress = rank_system.progress_to_next_rank(0, 0)
        assert progress == 0.0

    def test_progress_to_next_rank_halfway(self, rank_system):
        """Test progress calculation at halfway point."""
        rank0 = rank_system.get_rank(0)
        rank1 = rank_system.get_rank(1)

        midpoint_xp = (rank0.xp_required + rank1.xp_required) // 2
        progress = rank_system.progress_to_next_rank(midpoint_xp, 0)

        assert 40.0 < progress < 60.0  # Should be around 50%

    def test_progress_to_next_rank_at_max(self, rank_system):
        """Test progress calculation at max rank."""
        progress = rank_system.progress_to_next_rank(1000000, 99)
        assert progress == 100.0

    def test_is_max_rank(self, rank_system):
        """Test checking if at max rank."""
        assert not rank_system.is_max_rank(0)
        assert not rank_system.is_max_rank(50)
        assert rank_system.is_max_rank(99)

    def test_ranks_have_increasing_xp(self, rank_system):
        """Test that XP requirements increase for each rank."""
        for i in range(1, len(rank_system.ranks)):
            current = rank_system.get_rank(i)
            previous = rank_system.get_rank(i - 1)
            assert current.xp_required > previous.xp_required

    def test_all_ranks_have_symbols(self, rank_system):
        """Test that all ranks have unicode symbols."""
        for rank in rank_system.ranks:
            assert rank.symbol is not None
            assert len(rank.symbol) > 0

    def test_all_ranks_have_unique_ids(self, rank_system):
        """Test that all ranks have unique IDs."""
        ids = [rank.id for rank in rank_system.ranks]
        assert len(ids) == len(set(ids))
        assert ids == list(range(100))
