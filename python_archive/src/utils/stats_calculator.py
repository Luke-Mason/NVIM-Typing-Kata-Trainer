"""Statistics calculation utilities."""
from typing import Optional


def calculate_wpm(characters: int, seconds: float, word_length: int = 5) -> float:
    """
    Calculate words per minute.

    Args:
        characters: Number of characters typed
        seconds: Time taken in seconds
        word_length: Average word length (default 5 for standard WPM)

    Returns:
        Words per minute
    """
    if seconds <= 0:
        return 0.0

    words = characters / word_length
    minutes = seconds / 60
    return words / minutes if minutes > 0 else 0.0


def calculate_cpm(characters: int, seconds: float) -> float:
    """
    Calculate characters per minute.

    Args:
        characters: Number of characters typed
        seconds: Time taken in seconds

    Returns:
        Characters per minute
    """
    if seconds <= 0:
        return 0.0

    minutes = seconds / 60
    return characters / minutes if minutes > 0 else 0.0


def calculate_accuracy(correct: int, total: int) -> float:
    """
    Calculate accuracy percentage.

    Args:
        correct: Number of correct inputs
        total: Total number of inputs

    Returns:
        Accuracy as percentage (0-100)
    """
    if total <= 0:
        return 100.0
    return (correct / total) * 100


def calculate_xp_bonus(
    accuracy: float,
    speed_factor: float = 1.0,
    streak_count: int = 0,
    base_xp: int = 10
) -> int:
    """
    Calculate XP with bonuses.

    Args:
        accuracy: Accuracy percentage (0-100)
        speed_factor: Speed multiplier (typically 0-2, where 1 is average)
        streak_count: Current streak count
        base_xp: Base XP amount

    Returns:
        Total XP including bonuses
    """
    # Accuracy bonus (0-10 XP for 0-100% accuracy)
    accuracy_bonus = (accuracy / 100) * 10

    # Speed bonus (0-5 XP based on speed factor)
    speed_bonus = min(5.0, max(0.0, (speed_factor - 0.5) * 5))

    # Streak bonus (0-15 XP, increasing with streak)
    streak_bonus = min(15.0, streak_count * 0.5)

    total_xp = base_xp + accuracy_bonus + speed_bonus + streak_bonus
    return int(total_xp)


def format_time(seconds: float) -> str:
    """
    Format seconds into a readable time string.

    Args:
        seconds: Time in seconds

    Returns:
        Formatted string (e.g., "1h 23m 45s" or "45s")
    """
    if seconds < 60:
        return f"{int(seconds)}s"

    minutes = int(seconds // 60)
    secs = int(seconds % 60)

    if minutes < 60:
        return f"{minutes}m {secs}s"

    hours = minutes // 60
    mins = minutes % 60
    return f"{hours}h {mins}m {secs}s"


def create_progress_bar(
    current: float,
    maximum: float,
    width: int = 20,
    filled_char: str = "█",
    empty_char: str = "░"
) -> str:
    """
    Create a text-based progress bar.

    Args:
        current: Current value
        maximum: Maximum value
        width: Width of the bar in characters
        filled_char: Character for filled portion
        empty_char: Character for empty portion

    Returns:
        Progress bar string
    """
    if maximum <= 0:
        progress = 0.0
    else:
        progress = min(1.0, current / maximum)

    filled = int(width * progress)
    empty = width - filled

    bar = filled_char * filled + empty_char * empty
    percentage = progress * 100

    return f"[{bar}] {percentage:.1f}%"
