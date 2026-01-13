"""Coding Lessons Mode - Type code character-by-character with AI-generated lessons."""
import asyncio
import time
from typing import Optional, List

from .base_mode import BaseGameMode
from ..core.config import Config
from ..models.player import Player
from ..input.keyboard_handler import KeyEvent
from ..utils.stats_calculator import calculate_xp_bonus, calculate_wpm
from ..ai import LessonGenerator, DifficultyLevel, ProgrammingLanguage


class CodingLessonsMode(BaseGameMode):
    """Game mode for typing code character-by-character."""

    def __init__(self, config: Config, player: Player):
        """
        Initialize Coding Lessons mode.

        Args:
            config: Application configuration
            player: Player instance
        """
        super().__init__(config, player, mode_name="coding_lessons")

        self.lesson_generator = LessonGenerator(config)
        self.current_lesson: Optional[dict] = None
        self.target_code: str = ""
        self.typed_code: str = ""
        self.current_position: int = 0
        self.task_start_time: float = 0
        self.errors_made: int = 0

        # Settings
        self.language: ProgrammingLanguage = ProgrammingLanguage.PYTHON
        self.difficulty: DifficultyLevel = DifficultyLevel.BEGINNER

    async def setup(self):
        """Initialize the game mode."""
        pass

    async def generate_task(self):
        """Generate a new coding lesson."""
        # Generate lesson using AI
        try:
            self.current_lesson = await self.lesson_generator.generate_lesson(
                language=self.language,
                difficulty=self.difficulty
            )

            self.target_code = self.current_lesson.get('code', '')
            self.typed_code = ""
            self.current_position = 0
            self.errors_made = 0
            self.task_start_time = time.time()

        except Exception as e:
            # Fallback to simple code if generation fails
            self.target_code = "def hello():\n    print('Hello, World!')\n    return True"
            self.typed_code = ""
            self.current_position = 0
            self.errors_made = 0
            self.task_start_time = time.time()

    async def update(self, key_event: KeyEvent) -> bool:
        """
        Handle a key event.

        Args:
            key_event: The key event

        Returns:
            True if lesson completed
        """
        if self.current_position >= len(self.target_code):
            return False

        # Ignore modifier keys
        if key_event.key_name in ['Shift', 'Ctrl', 'Alt', 'Cmd']:
            return False

        # Get expected character
        expected_char = self.target_code[self.current_position]

        # Get typed character
        typed_char = None
        if key_event.key_name == 'Enter':
            typed_char = '\n'
        elif key_event.key_name == 'Tab':
            typed_char = '\t'
        elif key_event.key_name == 'Space':
            typed_char = ' '
        elif key_event.char:
            typed_char = key_event.char
        else:
            # Unknown key
            self.session.record_keystroke(correct=False)
            return False

        # Check if correct
        if typed_char == expected_char:
            # Correct!
            self.typed_code += typed_char
            self.current_position += 1
            self.session.record_keystroke(correct=True)

            # Check if lesson complete
            if self.current_position >= len(self.target_code):
                # Lesson complete!
                duration = time.time() - self.task_start_time

                # Calculate metrics
                accuracy = ((self.current_position - self.errors_made) / self.current_position * 100) if self.current_position > 0 else 100
                wpm = calculate_wpm(self.current_position, duration)

                # Calculate XP
                accuracy_bonus = accuracy / 100.0
                wpm_bonus = min(2.0, wpm / 40.0)  # 40 WPM = 1.0x, 80+ WPM = 2.0x

                xp = calculate_xp_bonus(
                    accuracy=accuracy,
                    speed_factor=wpm_bonus,
                    streak_count=self.session.current_streak,
                    base_xp=30  # Higher base XP for coding
                )

                # Record completion
                self.on_task_complete(xp)

                # Store stats
                stats = self.session.get_mode_data('coding_stats', {
                    'total_chars': 0,
                    'total_errors': 0,
                    'total_time': 0.0,
                    'lessons_completed': 0
                })
                stats['total_chars'] += self.current_position
                stats['total_errors'] += self.errors_made
                stats['total_time'] += duration
                stats['lessons_completed'] += 1
                self.session.set_mode_data('coding_stats', stats)

                return True

            return False

        # Wrong character
        self.errors_made += 1
        self.session.record_keystroke(correct=False)
        return False

    def get_display_text(self) -> str:
        """
        Get display text for the current state.

        Returns:
            Rich-formatted display text
        """
        lines = []

        lines.append("[bold cyan]💻 Coding Lessons[/]")
        lines.append("")

        # Show lesson info
        if self.current_lesson:
            lang = self.current_lesson.get('language', 'unknown')
            diff = self.current_lesson.get('difficulty', 'beginner')
            desc = self.current_lesson.get('description', '')

            lines.append(f"[yellow]Language:[/] {lang.title()} | [yellow]Difficulty:[/] {diff.title()}")

            if desc:
                lines.append(f"[dim]{desc}[/]")

            # Show practice tips if available
            practice = self.current_lesson.get('practice_movements', '')
            if practice:
                lines.append(f"[dim italic]{practice}[/]")

        lines.append("")

        # Show code with progress
        if self.target_code:
            display = self._format_code_with_progress()
            lines.append("[bold]Code to type:[/]")
            lines.extend(display.split('\n'))
        else:
            lines.append("[dim]Loading lesson...[/]")

        lines.append("")

        # Show stats
        progress_pct = (self.current_position / len(self.target_code) * 100) if self.target_code else 0
        lines.append(f"[cyan]Progress:[/] {progress_pct:.1f}% ({self.current_position}/{len(self.target_code)})")
        lines.append(f"[cyan]Errors:[/] {self.errors_made}")

        if self.current_position > 0:
            duration = time.time() - self.task_start_time
            wpm = calculate_wpm(self.current_position, duration)
            lines.append(f"[cyan]WPM:[/] {wpm:.1f}")

        lines.append(f"[cyan]Tasks Completed:[/] {self.session.tasks_completed}")
        lines.append(f"[cyan]XP Earned:[/] {self.session.xp_earned:,}")

        lines.append("")
        lines.append(f"[dim]Type the code exactly | Press '{self.config.universal_exit_sequence}' to exit[/]")

        return "\n".join(lines)

    def _format_code_with_progress(self) -> str:
        """Format code with typed portion highlighted."""
        if not self.target_code:
            return ""

        # Split into typed and remaining
        typed = self.target_code[:self.current_position]
        remaining = self.target_code[self.current_position:]

        # Highlight current character
        if remaining:
            current_char = remaining[0]
            rest = remaining[1:]

            # Escape special characters for rich
            typed_display = typed.replace('[', '\\[')
            current_display = current_char.replace('[', '\\[')
            rest_display = rest.replace('[', '\\[')

            # Show typed in green, current in yellow highlight, rest in dim
            return f"[green]{typed_display}[/][bold yellow on blue]{current_display}[/][dim]{rest_display}[/]"
        else:
            return f"[green]{typed.replace('[', '\\[')}[/]"

    def calculate_score(self) -> int:
        """Calculate XP for current task."""
        return 0  # Calculated in update()

    def set_language(self, language: ProgrammingLanguage):
        """
        Set the programming language.

        Args:
            language: Programming language
        """
        self.language = language

    def set_difficulty(self, difficulty: DifficultyLevel):
        """
        Set the difficulty level.

        Args:
            difficulty: Difficulty level
        """
        self.difficulty = difficulty

    def get_available_languages(self) -> List[str]:
        """Get list of available programming languages."""
        return self.lesson_generator.get_supported_languages()

    def get_available_difficulties(self) -> List[str]:
        """Get list of available difficulty levels."""
        return self.lesson_generator.get_difficulty_levels()

    def is_ai_available(self) -> bool:
        """Check if AI lesson generation is available."""
        return self.lesson_generator.is_ai_available()
