"""Vim Motions Mode - Complex vim operations with AI keystroke analysis."""
import asyncio
import time
from typing import Optional, List, Dict, Any

from .base_mode import BaseGameMode
from ..core.config import Config
from ..models.player import Player
from ..input.keyboard_handler import KeyEvent
from ..input.recorder import KeystrokeRecorder
from ..utils.stats_calculator import calculate_xp_bonus
from ..ai import KeystrokeAnalyzer


class VimMotionsMode(BaseGameMode):
    """Game mode for complex vim operations with AI feedback."""

    # Complex editing tasks
    EDITING_TASKS = [
        {
            "description": "Delete the word under cursor",
            "initial_text": "The quick brown fox jumps",
            "cursor_pos": 10,  # on 'brown'
            "optimal_solution": "daw",
            "expected_result": "The quick fox jumps"
        },
        {
            "description": "Change text inside parentheses",
            "initial_text": "function(old_argument)",
            "cursor_pos": 10,
            "optimal_solution": "ci(",
            "expected_result": "function()"
        },
        {
            "description": "Delete from cursor to end of line",
            "initial_text": "Keep this part, delete rest",
            "cursor_pos": 14,
            "optimal_solution": "D",
            "expected_result": "Keep this part"
        },
        {
            "description": "Go to line start and insert",
            "initial_text": "    indented text",
            "cursor_pos": 10,
            "optimal_solution": "^i",
            "expected_result": "    [insert mode]"
        },
        {
            "description": "Delete current line",
            "initial_text": "Line 1\nLine 2\nLine 3",
            "cursor_pos": 7,  # on Line 2
            "optimal_solution": "dd",
            "expected_result": "Line 1\nLine 3"
        },
        {
            "description": "Change word",
            "initial_text": "Replace this word here",
            "cursor_pos": 8,  # on 'this'
            "optimal_solution": "cw",
            "expected_result": "Replace [insert mode]"
        },
        {
            "description": "Delete inside quotes",
            "initial_text": 'Text "delete me" more',
            "cursor_pos": 10,
            "optimal_solution": 'di"',
            "expected_result": 'Text "" more'
        },
        {
            "description": "Yank (copy) current line",
            "initial_text": "Copy this line",
            "cursor_pos": 5,
            "optimal_solution": "yy",
            "expected_result": "[yanked]"
        },
    ]

    def __init__(self, config: Config, player: Player):
        """
        Initialize Vim Motions mode.

        Args:
            config: Application configuration
            player: Player instance
        """
        super().__init__(config, player, mode_name="vim_motions")

        self.keystroke_analyzer = KeystrokeAnalyzer(config)
        self.keystroke_recorder = KeystrokeRecorder()

        self.current_task: Optional[Dict[str, Any]] = None
        self.task_start_time: float = 0
        self.keystrokes_recorded: List[Dict[str, Any]] = []
        self.task_completed: bool = False
        self.ai_feedback: Optional[str] = None

    async def setup(self):
        """Initialize the game mode."""
        # Load vim/nvim context for AI
        self.keystroke_analyzer.load_all_vim_context(self.config.vimrc_path)

    async def generate_task(self):
        """Generate a new vim editing task."""
        import random
        self.current_task = random.choice(self.EDITING_TASKS).copy()
        self.task_start_time = time.time()
        self.keystrokes_recorded = []
        self.task_completed = False
        self.ai_feedback = None

        # Start recording keystrokes
        self.keystroke_recorder.start_recording()

    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a key event.

        Args:
            key_event: The key event

        Returns:
            True if task completed
        """
        if not self.current_task or self.task_completed:
            return False

        # Ignore modifier keys
        if key_event.key_name in ['Shift', 'Ctrl', 'Alt', 'Cmd']:
            return False

        # Record keystroke
        keystroke_data = {
            'key': key_event.key_name or key_event.char,
            'timestamp': time.time() - self.task_start_time,
            'char': key_event.char
        }
        self.keystrokes_recorded.append(keystroke_data)

        # For this mode, we simulate task completion after a reasonable number of keys
        # In a real implementation, this would check the actual vim state
        min_keys = len(self.current_task['optimal_solution'])

        if len(self.keystrokes_recorded) >= min_keys:
            # Task potentially complete
            # For demo purposes, we'll complete after 2x the optimal keystrokes
            if len(self.keystrokes_recorded) >= min_keys * 2:
                await self._complete_task()
                return True

            # Check if user pressed Enter (indicating they think they're done)
            if key_event.key_name == 'Enter':
                await self._complete_task()
                return True

        return False

    async def _complete_task(self):
        """Complete the current task and analyze keystrokes."""
        if self.task_completed:
            return

        self.task_completed = True
        duration = time.time() - self.task_start_time

        # Stop recording
        self.keystroke_recorder.stop_recording()

        # Calculate efficiency
        optimal_keys = len(self.current_task['optimal_solution'])
        actual_keys = len(self.keystrokes_recorded)
        efficiency = optimal_keys / actual_keys if actual_keys > 0 else 0

        # Calculate XP
        efficiency_bonus = min(2.0, max(0.5, efficiency * 1.5))
        speed_factor = max(0.5, min(2.0, 2.0 - (duration / 15.0)))

        xp = calculate_xp_bonus(
            accuracy=efficiency * 100,
            speed_factor=speed_factor * efficiency_bonus,
            streak_count=self.session.current_streak,
            base_xp=50  # Highest base XP
        )

        # Record completion
        self.session.record_keystroke(correct=True)
        self.on_task_complete(xp)

        # Store stats
        stats = self.session.get_mode_data('vim_motions_stats', {
            'total_keystrokes': 0,
            'optimal_keystrokes': 0,
            'tasks_analyzed': 0
        })
        stats['total_keystrokes'] += actual_keys
        stats['optimal_keystrokes'] += optimal_keys
        stats['tasks_analyzed'] += 1
        self.session.set_mode_data('vim_motions_stats', stats)

        # Get AI feedback if enabled
        if self.config.ai_feedback_timing != 'none':
            try:
                analysis = await self.keystroke_analyzer.analyze_sequence(
                    keystrokes=self.keystrokes_recorded,
                    task_description=self.current_task['description'],
                    provide_feedback=True
                )

                if 'ai_feedback' in analysis:
                    feedback = analysis['ai_feedback']
                    self.ai_feedback = feedback.get('analysis', 'Analysis complete')
            except Exception:
                # AI feedback failed, that's okay
                pass

    def get_display_text(self) -> str:
        """
        Get display text for the current state.

        Returns:
            Rich-formatted display text
        """
        lines = []

        lines.append("[bold cyan]⚡ Vim Motions - Advanced Training[/]")
        lines.append("")

        if self.current_task:
            # Show task
            lines.append("[bold yellow]Task:[/]")
            lines.append(f"  {self.current_task['description']}")
            lines.append("")

            # Show initial text
            lines.append("[bold green]Text:[/]")
            lines.append(f"  {self.current_task['initial_text']}")
            lines.append("")

            # Show optimal solution (hint)
            if self.session.current_streak < 3:
                lines.append(f"[dim]Hint: Try '{self.current_task['optimal_solution']}'[/]")
                lines.append("")

            # Show keystroke count
            optimal = len(self.current_task['optimal_solution'])
            actual = len(self.keystrokes_recorded)
            lines.append(f"[cyan]Keystrokes:[/] {actual} (optimal: {optimal})")

            # Show efficiency
            if actual > 0:
                efficiency = optimal / actual * 100
                color = "green" if efficiency >= 80 else "yellow" if efficiency >= 50 else "red"
                lines.append(f"[{color}]Efficiency:[/{color}] {efficiency:.1f}%")

            lines.append("")

        # Show AI feedback if available
        if self.ai_feedback:
            lines.append("[bold magenta]AI Feedback:[/]")
            # Show first 3 lines of feedback
            feedback_lines = self.ai_feedback.split('\n')[:3]
            for line in feedback_lines:
                lines.append(f"  [dim]{line}[/]")
            lines.append("")

        # Show session stats
        lines.append(f"[cyan]Tasks Completed:[/] {self.session.tasks_completed}")
        lines.append(f"[cyan]Current Streak:[/] {self.session.current_streak}")
        lines.append(f"[cyan]XP Earned:[/] {self.session.xp_earned:,}")

        # Show overall efficiency
        stats = self.session.get_mode_data('vim_motions_stats', {})
        if stats and 'total_keystrokes' in stats:
            overall_eff = (stats['optimal_keystrokes'] / stats['total_keystrokes'] * 100) if stats['total_keystrokes'] > 0 else 100
            lines.append(f"[cyan]Overall Efficiency:[/] {overall_eff:.1f}%")

        lines.append("")
        lines.append(f"[dim]Complete the task | Press Enter when done | '{self.config.universal_exit_sequence}' to exit[/]")

        return "\n".join(lines)

    def calculate_score(self) -> int:
        """Calculate XP for current task."""
        return 0  # Calculated in _complete_task()

    async def get_session_feedback(self) -> str:
        """
        Get AI feedback for the entire session.

        Returns:
            Feedback message
        """
        session_data = {
            'tasks_completed': self.session.tasks_completed,
            'accuracy': self.session.calculate_accuracy(),
            'best_streak': self.session.best_streak,
            'xp_earned': self.session.xp_earned,
            'duration': self.session.duration_seconds()
        }

        try:
            feedback = await self.keystroke_analyzer.get_session_feedback(
                session_data=session_data,
                mode_name=self.mode_name
            )
            return feedback
        except Exception:
            return "Great session! Keep practicing vim motions."

    def is_ai_available(self) -> bool:
        """Check if AI analysis is available."""
        return self.keystroke_analyzer.is_ai_available()
