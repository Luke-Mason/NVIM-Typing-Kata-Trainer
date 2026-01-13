"""Tests for stats calculator utilities."""
import pytest

from src.utils.stats_calculator import (
    calculate_wpm,
    calculate_cpm,
    calculate_accuracy,
    calculate_xp_bonus,
    format_time,
    create_progress_bar
)


class TestCalculateWPM:
    """Tests for WPM calculation."""

    def test_calculate_wpm_standard(self):
        """Test standard WPM calculation."""
        # 250 characters in 60 seconds = 50 WPM (250/5/1)
        wpm = calculate_wpm(250, 60)
        assert wpm == 50.0

    def test_calculate_wpm_faster(self):
        """Test WPM for faster typing."""
        # 500 characters in 60 seconds = 100 WPM
        wpm = calculate_wpm(500, 60)
        assert wpm == 100.0

    def test_calculate_wpm_slower(self):
        """Test WPM for slower typing."""
        # 125 characters in 60 seconds = 25 WPM
        wpm = calculate_wpm(125, 60)
        assert wpm == 25.0

    def test_calculate_wpm_zero_seconds(self):
        """Test WPM with zero seconds."""
        wpm = calculate_wpm(100, 0)
        assert wpm == 0.0

    def test_calculate_wpm_custom_word_length(self):
        """Test WPM with custom word length."""
        # 300 characters, 60 seconds, word length 6 = 50 WPM (300/6/1)
        wpm = calculate_wpm(300, 60, word_length=6)
        assert wpm == 50.0


class TestCalculateCPM:
    """Tests for CPM calculation."""

    def test_calculate_cpm_standard(self):
        """Test standard CPM calculation."""
        # 250 characters in 60 seconds = 250 CPM
        cpm = calculate_cpm(250, 60)
        assert cpm == 250.0

    def test_calculate_cpm_faster(self):
        """Test CPM for faster typing."""
        # 300 characters in 30 seconds = 600 CPM
        cpm = calculate_cpm(300, 30)
        assert cpm == 600.0

    def test_calculate_cpm_zero_seconds(self):
        """Test CPM with zero seconds."""
        cpm = calculate_cpm(100, 0)
        assert cpm == 0.0


class TestCalculateAccuracy:
    """Tests for accuracy calculation."""

    def test_calculate_accuracy_perfect(self):
        """Test perfect accuracy."""
        accuracy = calculate_accuracy(100, 100)
        assert accuracy == 100.0

    def test_calculate_accuracy_half(self):
        """Test 50% accuracy."""
        accuracy = calculate_accuracy(50, 100)
        assert accuracy == 50.0

    def test_calculate_accuracy_zero_total(self):
        """Test accuracy with zero total."""
        accuracy = calculate_accuracy(0, 0)
        assert accuracy == 100.0  # Default to perfect

    def test_calculate_accuracy_rounding(self):
        """Test accuracy with rounding."""
        accuracy = calculate_accuracy(2, 3)
        assert abs(accuracy - 66.67) < 0.01


class TestCalculateXPBonus:
    """Tests for XP bonus calculation."""

    def test_calculate_xp_base_only(self):
        """Test XP with only base amount."""
        xp = calculate_xp_bonus(
            accuracy=0.0,
            speed_factor=0.5,  # Minimum
            streak_count=0,
            base_xp=10
        )

        # Should be close to base XP
        assert xp >= 10

    def test_calculate_xp_perfect_accuracy(self):
        """Test XP with perfect accuracy."""
        xp = calculate_xp_bonus(
            accuracy=100.0,
            speed_factor=1.0,
            streak_count=0,
            base_xp=10
        )

        # Should be base + 10 (accuracy bonus) + speed bonus
        assert xp > 10

    def test_calculate_xp_with_speed_bonus(self):
        """Test XP with speed bonus."""
        xp = calculate_xp_bonus(
            accuracy=0.0,
            speed_factor=2.0,  # Fast
            streak_count=0,
            base_xp=10
        )

        # Should include speed bonus
        assert xp > 10

    def test_calculate_xp_with_streak(self):
        """Test XP with streak bonus."""
        xp = calculate_xp_bonus(
            accuracy=0.0,
            speed_factor=1.0,
            streak_count=10,
            base_xp=10
        )

        # Should include streak bonus
        assert xp > 10

    def test_calculate_xp_all_bonuses(self):
        """Test XP with all bonuses."""
        xp = calculate_xp_bonus(
            accuracy=100.0,
            speed_factor=2.0,
            streak_count=10,
            base_xp=10
        )

        # Should be significantly higher than base
        assert xp > 20

    def test_calculate_xp_streak_cap(self):
        """Test that streak bonus is capped."""
        xp1 = calculate_xp_bonus(
            accuracy=100.0,
            speed_factor=1.0,
            streak_count=30,  # Very high
            base_xp=10
        )

        xp2 = calculate_xp_bonus(
            accuracy=100.0,
            speed_factor=1.0,
            streak_count=100,  # Even higher
            base_xp=10
        )

        # Both should be capped at same value
        assert xp1 == xp2


class TestFormatTime:
    """Tests for time formatting."""

    def test_format_time_seconds(self):
        """Test formatting seconds only."""
        assert format_time(45) == "45s"
        assert format_time(0) == "0s"

    def test_format_time_minutes(self):
        """Test formatting minutes and seconds."""
        assert format_time(60) == "1m 0s"
        assert format_time(90) == "1m 30s"
        assert format_time(125) == "2m 5s"

    def test_format_time_hours(self):
        """Test formatting hours, minutes, and seconds."""
        assert format_time(3600) == "1h 0m 0s"
        assert format_time(3661) == "1h 1m 1s"
        assert format_time(7200) == "2h 0m 0s"
        assert format_time(3725) == "1h 2m 5s"

    def test_format_time_rounding(self):
        """Test that fractional seconds are rounded."""
        result = format_time(45.7)
        assert result == "45s"


class TestCreateProgressBar:
    """Tests for progress bar creation."""

    def test_create_progress_bar_empty(self):
        """Test empty progress bar."""
        bar = create_progress_bar(0, 100)
        assert "░" * 20 in bar
        assert "0.0%" in bar

    def test_create_progress_bar_half(self):
        """Test half-full progress bar."""
        bar = create_progress_bar(50, 100, width=20)
        assert "█" in bar
        assert "░" in bar
        assert "50.0%" in bar

    def test_create_progress_bar_full(self):
        """Test full progress bar."""
        bar = create_progress_bar(100, 100)
        assert "█" * 20 in bar
        assert "100.0%" in bar

    def test_create_progress_bar_custom_width(self):
        """Test progress bar with custom width."""
        bar = create_progress_bar(50, 100, width=10)
        # Should have 10 characters total
        assert bar.count("█") + bar.count("░") >= 10

    def test_create_progress_bar_custom_characters(self):
        """Test progress bar with custom characters."""
        bar = create_progress_bar(
            50, 100,
            filled_char="#",
            empty_char="-"
        )
        assert "#" in bar
        assert "-" in bar

    def test_create_progress_bar_over_maximum(self):
        """Test progress bar with current > maximum."""
        bar = create_progress_bar(150, 100)
        assert "100.0%" in bar

    def test_create_progress_bar_zero_maximum(self):
        """Test progress bar with zero maximum."""
        bar = create_progress_bar(50, 0)
        assert "0.0%" in bar
