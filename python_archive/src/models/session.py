"""Game session data model."""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Dict, Any, Optional


@dataclass
class GameSession:
    """Represents a single game session for a specific mode."""
    mode: str
    start_time: datetime = field(default_factory=datetime.now)
    end_time: Optional[datetime] = None

    # Task completion tracking
    tasks_completed: int = 0
    current_streak: int = 0
    best_streak: int = 0

    # Accuracy tracking
    total_keystrokes: int = 0
    correct_keystrokes: int = 0
    errors: int = 0

    # XP earned this session
    xp_earned: int = 0

    # Mode-specific data (flexible storage)
    mode_data: Dict[str, Any] = field(default_factory=dict)

    # Exit status
    exited: bool = False

    def start(self):
        """Start the session."""
        self.start_time = datetime.now()
        self.exited = False

    def end(self):
        """End the session."""
        self.end_time = datetime.now()
        self.exited = True

    def duration_seconds(self) -> float:
        """
        Calculate session duration in seconds.

        Returns:
            Duration in seconds (0 if not ended)
        """
        if self.end_time is None:
            # Session still ongoing
            return (datetime.now() - self.start_time).total_seconds()
        return (self.end_time - self.start_time).total_seconds()

    def add_task_completion(self, xp: int):
        """
        Record a completed task.

        Args:
            xp: XP earned for this task
        """
        self.tasks_completed += 1
        self.xp_earned += xp
        self.current_streak += 1

        if self.current_streak > self.best_streak:
            self.best_streak = self.current_streak

    def break_streak(self):
        """Break the current streak (e.g., on error or exit)."""
        self.current_streak = 0

    def record_keystroke(self, correct: bool):
        """
        Record a keystroke.

        Args:
            correct: Whether the keystroke was correct
        """
        self.total_keystrokes += 1
        if correct:
            self.correct_keystrokes += 1
        else:
            self.errors += 1

    def calculate_accuracy(self) -> float:
        """
        Calculate accuracy percentage.

        Returns:
            Accuracy as a percentage (0-100), or 100 if no keystrokes
        """
        if self.total_keystrokes == 0:
            return 100.0
        return (self.correct_keystrokes / self.total_keystrokes) * 100

    def calculate_error_rate(self) -> float:
        """
        Calculate error rate percentage.

        Returns:
            Error rate as a percentage (0-100)
        """
        if self.total_keystrokes == 0:
            return 0.0
        return (self.errors / self.total_keystrokes) * 100

    def get_mode_data(self, key: str, default: Any = None) -> Any:
        """
        Get mode-specific data.

        Args:
            key: Key to retrieve
            default: Default value if key not found

        Returns:
            Value associated with key, or default
        """
        return self.mode_data.get(key, default)

    def set_mode_data(self, key: str, value: Any):
        """
        Set mode-specific data.

        Args:
            key: Key to set
            value: Value to store
        """
        self.mode_data[key] = value

    def __str__(self) -> str:
        """String representation."""
        duration = self.duration_seconds()
        return (
            f"GameSession({self.mode}, "
            f"{self.tasks_completed} tasks, "
            f"{self.calculate_accuracy():.1f}% accuracy, "
            f"{duration:.1f}s)"
        )
