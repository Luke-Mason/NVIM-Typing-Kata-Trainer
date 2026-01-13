"""Constants and configuration values for the application."""
import time
from typing import List, Tuple

# Universal exit sequence configuration
DEFAULT_EXIT_SEQUENCE = "jk"
EXIT_SEQUENCE_TIMEOUT = 0.5  # seconds

# AI feedback timing options
AI_FEEDBACK_AFTER_EACH = "after_each_task"
AI_FEEDBACK_END_SESSION = "end_of_session"
AI_FEEDBACK_NONE = "none"

# Game difficulty levels
DIFFICULTY_BEGINNER = "beginner"
DIFFICULTY_EASY = "easy"
DIFFICULTY_MEDIUM = "medium"
DIFFICULTY_HARD = "hard"
DIFFICULTY_EXPERT = "expert"

DIFFICULTY_LEVELS = [
    DIFFICULTY_BEGINNER,
    DIFFICULTY_EASY,
    DIFFICULTY_MEDIUM,
    DIFFICULTY_HARD,
    DIFFICULTY_EXPERT,
]

# XP calculation constants
XP_BASE_PER_TASK = 10
XP_ACCURACY_MULTIPLIER = 0.1  # 0-10 bonus based on accuracy
XP_SPEED_MULTIPLIER = 5  # 0-5 bonus based on speed
XP_STREAK_MULTIPLIER = 15  # 0-15 bonus based on streak


class ExitSequenceDetector:
    """Detects when the universal exit sequence is pressed."""

    def __init__(self, sequence: str = DEFAULT_EXIT_SEQUENCE, timeout: float = EXIT_SEQUENCE_TIMEOUT):
        self.sequence = sequence.lower()
        self.timeout = timeout
        self.buffer: List[Tuple[str, float]] = []

    def check(self, key: str) -> bool:
        """
        Check if the exit sequence has been entered.

        Args:
            key: The key that was pressed (as a string)

        Returns:
            True if the exit sequence is detected, False otherwise
        """
        now = time.time()

        # Add to buffer if it's a regular character
        if key and len(key) == 1:
            self.buffer.append((key.lower(), now))

        # Remove old keys outside the timeout window
        self.buffer = [(k, t) for k, t in self.buffer if now - t < self.timeout]

        # Check if the sequence matches
        recent_keys = ''.join([k for k, _ in self.buffer])

        if self.sequence in recent_keys:
            # Clear buffer after detecting sequence
            self.buffer = []
            return True

        return False

    def reset(self):
        """Reset the buffer."""
        self.buffer = []
