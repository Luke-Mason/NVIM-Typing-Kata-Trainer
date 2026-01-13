"""Keystroke recording for vim motion analysis."""
import time
from typing import List, Tuple
from dataclasses import dataclass

from .keyboard_handler import KeyEvent


@dataclass
class RecordedKeystroke:
    """A single recorded keystroke with timing."""
    key_string: str  # Human-readable key representation
    timestamp: float  # Relative timestamp from recording start
    modifiers: str  # Modifier keys as string

    def __str__(self) -> str:
        """String representation."""
        if self.modifiers:
            return f"{self.modifiers}+{self.key_string}"
        return self.key_string


class KeystrokeRecorder:
    """Records keystrokes for analysis."""

    def __init__(self):
        """Initialize the keystroke recorder."""
        self.keystrokes: List[RecordedKeystroke] = []
        self.start_time: float = 0
        self.is_recording: bool = False

    def start_recording(self):
        """Start recording keystrokes."""
        self.keystrokes = []
        self.start_time = time.time()
        self.is_recording = True

    def stop_recording(self):
        """Stop recording keystrokes."""
        self.is_recording = False

    def record(self, key_event: KeyEvent):
        """
        Record a key event.

        Args:
            key_event: KeyEvent to record
        """
        if not self.is_recording:
            return

        timestamp = time.time() - self.start_time

        # Format modifiers
        modifiers_str = '+'.join(sorted(key_event.modifiers)) if key_event.modifiers else ""

        recorded = RecordedKeystroke(
            key_string=key_event.key_name,
            timestamp=timestamp,
            modifiers=modifiers_str
        )

        self.keystrokes.append(recorded)

    def get_keystrokes(self) -> List[str]:
        """
        Get list of keystroke strings for AI analysis.

        Returns:
            List of keystroke strings (e.g., ["j", "j", "w", "Ctrl+d"])
        """
        return [str(ks) for ks in self.keystrokes]

    def get_keystroke_sequence(self) -> str:
        """
        Get keystroke sequence as a single string.

        Returns:
            Space-separated keystroke sequence
        """
        return ' '.join(self.get_keystrokes())

    def get_detailed_keystrokes(self) -> List[RecordedKeystroke]:
        """
        Get detailed keystroke list with timing.

        Returns:
            List of RecordedKeystroke objects
        """
        return self.keystrokes.copy()

    def get_statistics(self) -> dict:
        """
        Get statistics about recorded keystrokes.

        Returns:
            Dictionary with recording statistics
        """
        if not self.keystrokes:
            return {
                'total_keystrokes': 0,
                'duration': 0.0,
                'keystrokes_per_second': 0.0
            }

        duration = self.keystrokes[-1].timestamp if self.keystrokes else 0.0

        return {
            'total_keystrokes': len(self.keystrokes),
            'duration': duration,
            'keystrokes_per_second': len(self.keystrokes) / duration if duration > 0 else 0.0,
            'unique_keys': len(set(str(ks) for ks in self.keystrokes))
        }

    def clear(self):
        """Clear all recorded keystrokes."""
        self.keystrokes = []
        self.start_time = 0
        self.is_recording = False

    def export_to_dict(self) -> dict:
        """
        Export recording to dictionary format.

        Returns:
            Dictionary with all recording data
        """
        return {
            'keystrokes': [
                {
                    'key': ks.key_string,
                    'modifiers': ks.modifiers,
                    'timestamp': ks.timestamp
                }
                for ks in self.keystrokes
            ],
            'statistics': self.get_statistics(),
            'sequence': self.get_keystroke_sequence()
        }

    def __len__(self) -> int:
        """Get number of recorded keystrokes."""
        return len(self.keystrokes)

    def __str__(self) -> str:
        """String representation."""
        return f"KeystrokeRecorder({len(self.keystrokes)} keystrokes recorded)"
