"""AI-powered keystroke analyzer for vim motion feedback."""
import asyncio
from typing import List, Dict, Any, Optional
from datetime import datetime

from .claude_client import ClaudeClient
from ..core.config import Config


class KeystrokeAnalyzer:
    """Analyzes keystroke sequences for vim efficiency."""

    def __init__(self, config: Config):
        """
        Initialize keystroke analyzer.

        Args:
            config: Application configuration
        """
        self.config = config
        self.claude_client: Optional[ClaudeClient] = None

        # Try to initialize Claude client
        try:
            if config.claude_api_key:
                self.claude_client = ClaudeClient(config)
        except Exception:
            # Claude client not available
            pass

        # Cache for vimrc config
        self.vimrc_context: Optional[str] = None

    async def analyze_sequence(
        self,
        keystrokes: List[Dict[str, Any]],
        task_description: str,
        provide_feedback: bool = True
    ) -> Dict[str, Any]:
        """
        Analyze a sequence of keystrokes.

        Args:
            keystrokes: List of keystroke records with 'key' and 'timestamp'
            task_description: What the user was trying to accomplish
            provide_feedback: Whether to generate AI feedback

        Returns:
            Analysis results with metrics and optional suggestions
        """
        # Calculate basic metrics
        metrics = self._calculate_metrics(keystrokes)

        result = {
            "task": task_description,
            "keystroke_count": len(keystrokes),
            "duration": metrics["duration"],
            "keys_per_second": metrics["kps"],
            "unique_keys": metrics["unique_keys"],
            "timestamp": datetime.now().isoformat()
        }

        # Add AI feedback if requested and available
        if provide_feedback and self.is_ai_available():
            try:
                feedback = await self.claude_client.analyze_keystrokes(
                    keystrokes=keystrokes,
                    task_description=task_description,
                    vimrc_config=self.vimrc_context
                )
                result["ai_feedback"] = feedback
            except Exception as e:
                result["ai_feedback_error"] = str(e)

        return result

    def _calculate_metrics(self, keystrokes: List[Dict[str, Any]]) -> Dict[str, float]:
        """
        Calculate basic metrics from keystrokes.

        Args:
            keystrokes: List of keystroke records

        Returns:
            Dictionary of metrics
        """
        if not keystrokes:
            return {
                "duration": 0.0,
                "kps": 0.0,
                "unique_keys": 0
            }

        # Get timestamps
        timestamps = [ks.get("timestamp", 0) for ks in keystrokes]
        duration = max(timestamps) - min(timestamps) if timestamps else 0

        # Keys per second
        kps = len(keystrokes) / duration if duration > 0 else 0

        # Unique keys used
        keys = [ks.get("key", "") for ks in keystrokes]
        unique_keys = len(set(keys))

        return {
            "duration": duration,
            "kps": kps,
            "unique_keys": unique_keys
        }

    def load_vimrc_context(self, vimrc_path: Optional[str] = None):
        """
        Load vimrc configuration for context in analysis.

        Args:
            vimrc_path: Path to vimrc file (uses config default if not provided)
        """
        path = vimrc_path or self.config.vimrc_path

        if not path:
            return

        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Extract key mappings for context
            lines = content.split('\n')
            mappings = [line for line in lines if 'map' in line.lower()]

            if mappings:
                self.vimrc_context = "Custom key mappings:\n" + "\n".join(mappings[:20])  # Limit to first 20
        except Exception:
            # Couldn't load vimrc, that's okay
            pass

    def load_nvim_context(self):
        """Load Neovim configuration for context in analysis."""
        try:
            from ..core.nvim_parser import NvimConfigParser

            parser = NvimConfigParser()
            if parser.parse():
                self.vimrc_context = parser.get_keymaps_summary()
        except Exception:
            # Couldn't load nvim config, that's okay
            pass

    def load_all_vim_context(self, vimrc_path: Optional[str] = None):
        """
        Load both vimrc and Neovim context for comprehensive analysis.

        Args:
            vimrc_path: Optional path to vimrc file
        """
        # Try Neovim first (more common for modern setups)
        self.load_nvim_context()

        # If no nvim context, try vimrc
        if not self.vimrc_context:
            self.load_vimrc_context(vimrc_path)

    async def get_session_feedback(
        self,
        session_data: Dict[str, Any],
        mode_name: str
    ) -> str:
        """
        Get AI feedback for a completed training session.

        Args:
            session_data: Session statistics
            mode_name: Name of the game mode

        Returns:
            Feedback message
        """
        if not self.is_ai_available():
            return self._get_fallback_feedback(session_data)

        try:
            feedback = await self.claude_client.get_feedback_for_session(
                session_data=session_data,
                mode_name=mode_name
            )
            return feedback
        except Exception:
            return self._get_fallback_feedback(session_data)

    def _get_fallback_feedback(self, session_data: Dict[str, Any]) -> str:
        """
        Generate basic feedback without AI.

        Args:
            session_data: Session statistics

        Returns:
            Feedback message
        """
        tasks = session_data.get('tasks_completed', 0)
        accuracy = session_data.get('accuracy', 0)
        xp = session_data.get('xp_earned', 0)

        if accuracy >= 95:
            feedback = f"Excellent work! {tasks} tasks with {accuracy:.1f}% accuracy. "
        elif accuracy >= 80:
            feedback = f"Good job! {tasks} tasks completed. "
        else:
            feedback = f"Keep practicing! {tasks} tasks completed. "

        if xp > 500:
            feedback += f"Great XP gain: {xp:,}!"
        elif xp > 200:
            feedback += f"Nice progress: {xp:,} XP."
        else:
            feedback += "Every session helps you improve!"

        return feedback

    def analyze_efficiency(self, keystrokes: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Analyze efficiency metrics of keystrokes (without AI).

        Args:
            keystrokes: List of keystroke records

        Returns:
            Efficiency metrics
        """
        if not keystrokes:
            return {"efficiency_score": 0}

        metrics = self._calculate_metrics(keystrokes)

        # Simple efficiency heuristics
        efficiency_score = 100

        # Penalize excessive keystrokes
        if len(keystrokes) > 50:
            efficiency_score -= min(30, (len(keystrokes) - 50) * 0.5)

        # Penalize slow speed
        if metrics["kps"] < 2.0:
            efficiency_score -= 20
        elif metrics["kps"] < 3.0:
            efficiency_score -= 10

        # Reward diverse key usage (shows knowledge of different commands)
        diversity_ratio = metrics["unique_keys"] / len(keystrokes) if len(keystrokes) > 0 else 0
        if diversity_ratio > 0.5:
            efficiency_score += 10

        efficiency_score = max(0, min(100, efficiency_score))

        return {
            "efficiency_score": efficiency_score,
            "metrics": metrics,
            "suggestions": self._get_efficiency_suggestions(efficiency_score, metrics)
        }

    def _get_efficiency_suggestions(
        self,
        score: float,
        metrics: Dict[str, float]
    ) -> List[str]:
        """
        Generate efficiency suggestions based on metrics.

        Args:
            score: Efficiency score
            metrics: Calculated metrics

        Returns:
            List of suggestion strings
        """
        suggestions = []

        if score < 50:
            suggestions.append("Try using more efficient vim motions like 'w', 'b', 'f', and '$'")

        if metrics["kps"] < 2.0:
            suggestions.append("Practice speed by doing quick key exercises")

        if metrics["unique_keys"] < 5:
            suggestions.append("Learn more vim commands to expand your toolkit")

        if not suggestions:
            suggestions.append("Great work! Keep practicing to maintain your skills")

        return suggestions

    def is_ai_available(self) -> bool:
        """
        Check if AI analysis is available.

        Returns:
            True if Claude client is configured
        """
        return self.claude_client is not None and self.claude_client.is_configured()
