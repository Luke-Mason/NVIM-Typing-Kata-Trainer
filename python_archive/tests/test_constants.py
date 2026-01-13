"""Tests for constants and exit sequence detector."""
import pytest
import time

from src.core.constants import ExitSequenceDetector


class TestExitSequenceDetector:
    """Tests for the ExitSequenceDetector class."""

    def test_detector_creation(self):
        """Test creating an exit sequence detector."""
        detector = ExitSequenceDetector("jk", timeout=0.5)
        assert detector.sequence == "jk"
        assert detector.timeout == 0.5
        assert len(detector.buffer) == 0

    def test_detector_default_values(self):
        """Test detector with default values."""
        detector = ExitSequenceDetector()
        assert detector.sequence == "jk"
        assert detector.timeout == 0.5

    def test_detect_sequence_simple(self):
        """Test detecting simple sequence."""
        detector = ExitSequenceDetector("jk")

        assert not detector.check("j")  # First key
        assert detector.check("k")  # Second key completes sequence

    def test_detect_sequence_case_insensitive(self):
        """Test that detection is case-insensitive."""
        detector = ExitSequenceDetector("jk")

        assert not detector.check("J")  # Uppercase J
        assert detector.check("K")  # Uppercase K

    def test_sequence_with_timeout(self):
        """Test that sequence times out."""
        detector = ExitSequenceDetector("jk", timeout=0.1)

        detector.check("j")
        time.sleep(0.15)  # Wait longer than timeout
        result = detector.check("k")

        # Should not detect because too much time passed
        assert not result

    def test_sequence_clears_after_detection(self):
        """Test that buffer clears after detection."""
        detector = ExitSequenceDetector("jk")

        detector.check("j")
        detector.check("k")  # Sequence detected

        # Buffer should be cleared
        assert len(detector.buffer) == 0

    def test_sequence_with_extra_keys(self):
        """Test sequence detection with extra keys."""
        detector = ExitSequenceDetector("jk")

        detector.check("x")  # Extra key
        detector.check("j")  # Start of sequence
        assert detector.check("k")  # Completes sequence

    def test_sequence_longer_than_two(self):
        """Test longer sequences."""
        detector = ExitSequenceDetector("abc")

        assert not detector.check("a")
        assert not detector.check("b")
        assert detector.check("c")

    def test_reset_clears_buffer(self):
        """Test that reset clears the buffer."""
        detector = ExitSequenceDetector("jk")

        detector.check("j")
        assert len(detector.buffer) > 0

        detector.reset()
        assert len(detector.buffer) == 0

    def test_ignores_none_keys(self):
        """Test that None keys are ignored."""
        detector = ExitSequenceDetector("jk")

        detector.check(None)
        assert len(detector.buffer) == 0

    def test_ignores_empty_strings(self):
        """Test that empty strings are ignored."""
        detector = ExitSequenceDetector("jk")

        detector.check("")
        assert len(detector.buffer) == 0

    def test_partial_sequence_then_timeout(self):
        """Test partial sequence followed by timeout."""
        detector = ExitSequenceDetector("jkl", timeout=0.1)

        detector.check("j")
        detector.check("k")
        time.sleep(0.15)
        detector.check("l")

        # Should have timed out, buffer should only have "l"
        assert not detector.check("x")

    def test_multiple_sequences(self):
        """Test detecting multiple sequences in succession."""
        detector = ExitSequenceDetector("jk")

        # First sequence
        detector.check("j")
        assert detector.check("k")

        # Second sequence
        detector.check("j")
        assert detector.check("k")

    def test_buffer_cleanup(self):
        """Test that old keys are removed from buffer."""
        detector = ExitSequenceDetector("jk", timeout=0.1)

        detector.check("a")
        time.sleep(0.15)
        detector.check("j")  # This should trigger cleanup

        # Buffer should only have "j", not "a"
        assert len(detector.buffer) == 1

    def test_sequence_in_middle_of_typing(self):
        """Test detecting sequence among other keypresses."""
        detector = ExitSequenceDetector("jk")

        detector.check("h")
        detector.check("e")
        detector.check("l")
        detector.check("j")  # Start of exit sequence
        detected = detector.check("k")  # End of exit sequence

        assert detected

    def test_repeated_character_sequence(self):
        """Test sequence with repeated characters."""
        detector = ExitSequenceDetector("aa")

        assert not detector.check("a")  # First 'a'
        assert detector.check("a")  # Second 'a' completes it

    def test_long_buffer_maintenance(self):
        """Test that buffer doesn't grow indefinitely."""
        detector = ExitSequenceDetector("jk", timeout=0.1)

        # Type many keys
        for char in "abcdefghijklmnopqrstuvwxyz":
            detector.check(char)
            time.sleep(0.02)

        # Buffer should only contain recent keys within timeout
        assert len(detector.buffer) <= 5  # Should be small due to cleanup
