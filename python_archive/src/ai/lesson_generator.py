"""AI-powered lesson generator for coding practice."""
import asyncio
from typing import List, Dict, Any, Optional
from enum import Enum

from .claude_client import ClaudeClient
from ..core.config import Config


class DifficultyLevel(str, Enum):
    """Lesson difficulty levels."""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class ProgrammingLanguage(str, Enum):
    """Supported programming languages."""
    PYTHON = "python"
    JAVASCRIPT = "javascript"
    TYPESCRIPT = "typescript"
    JAVA = "java"
    CPP = "cpp"
    C = "c"
    RUST = "rust"
    GO = "go"
    RUBY = "ruby"
    PHP = "php"
    CSHARP = "csharp"
    HTML = "html"
    CSS = "css"
    SQL = "sql"
    BASH = "bash"


class LessonGenerator:
    """Generates coding lessons using Claude AI."""

    # Pre-built lessons as fallback if AI is unavailable
    FALLBACK_LESSONS = {
        "python": {
            "beginner": [
                {
                    "code": "def greet(name):\n    print(f'Hello, {name}!')\n\ngreet('World')",
                    "description": "Simple function that greets a user",
                    "practice_movements": "Practice: w (word), $ (end of line), f (find character)"
                },
                {
                    "code": "numbers = [1, 2, 3, 4, 5]\ntotal = sum(numbers)\nprint(f'Sum: {total}')",
                    "description": "Basic list operations and printing",
                    "practice_movements": "Practice: j/k (line), w/b (word), % (matching bracket)"
                }
            ],
            "intermediate": [
                {
                    "code": "class Calculator:\n    def add(self, a, b):\n        return a + b\n    \n    def subtract(self, a, b):\n        return a - b\n\ncalc = Calculator()\nprint(calc.add(5, 3))",
                    "description": "Simple calculator class with methods",
                    "practice_movements": "Practice: { } (paragraph), ci( (change in parentheses), dd (delete line)"
                }
            ]
        },
        "javascript": {
            "beginner": [
                {
                    "code": "function greet(name) {\n    console.log(`Hello, ${name}!`);\n}\n\ngreet('World');",
                    "description": "Basic JavaScript function",
                    "practice_movements": "Practice: w/b (word), f/F (find), ci{ (change in braces)"
                }
            ]
        }
    }

    def __init__(self, config: Config):
        """
        Initialize lesson generator.

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
            # Claude client not available, will use fallback lessons
            pass

    async def generate_lesson(
        self,
        language: ProgrammingLanguage,
        difficulty: DifficultyLevel = DifficultyLevel.BEGINNER,
        topic: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Generate a coding lesson.

        Args:
            language: Programming language
            difficulty: Difficulty level
            topic: Optional specific topic

        Returns:
            Lesson dictionary with code, description, and practice info
        """
        # Try AI generation first
        if self.claude_client and self.claude_client.is_configured():
            try:
                lesson = await self.claude_client.generate_coding_lesson(
                    language=language.value,
                    difficulty=difficulty.value,
                    topic=topic
                )
                return lesson
            except Exception as e:
                # Fall back to pre-built lessons
                print(f"AI lesson generation failed: {e}, using fallback")

        # Use fallback lessons
        return self._get_fallback_lesson(language, difficulty)

    def _get_fallback_lesson(
        self,
        language: ProgrammingLanguage,
        difficulty: DifficultyLevel
    ) -> Dict[str, Any]:
        """
        Get a pre-built fallback lesson.

        Args:
            language: Programming language
            difficulty: Difficulty level

        Returns:
            Lesson dictionary
        """
        lang_key = language.value
        diff_key = difficulty.value

        # Check if we have fallback lessons for this combination
        if lang_key in self.FALLBACK_LESSONS:
            if diff_key in self.FALLBACK_LESSONS[lang_key]:
                lessons = self.FALLBACK_LESSONS[lang_key][diff_key]
                import random
                lesson = random.choice(lessons)
                return {
                    "code": lesson["code"],
                    "description": lesson["description"],
                    "practice_movements": lesson["practice_movements"],
                    "language": lang_key,
                    "difficulty": diff_key,
                    "is_fallback": True
                }

        # Default fallback
        return {
            "code": f"// {language.value} code example\n// Practice typing this code!\nfunction example() {{\n    return 'Hello, World!';\n}}",
            "description": f"Basic {language.value} example",
            "practice_movements": "Practice: w, b, f, $, ^",
            "language": lang_key,
            "difficulty": diff_key,
            "is_fallback": True
        }

    async def generate_lesson_batch(
        self,
        language: ProgrammingLanguage,
        difficulty: DifficultyLevel,
        count: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Generate multiple lessons at once.

        Args:
            language: Programming language
            difficulty: Difficulty level
            count: Number of lessons to generate

        Returns:
            List of lesson dictionaries
        """
        lessons = []
        for _ in range(count):
            lesson = await self.generate_lesson(language, difficulty)
            lessons.append(lesson)
            # Small delay to avoid rate limiting
            await asyncio.sleep(0.5)
        return lessons

    def get_supported_languages(self) -> List[str]:
        """
        Get list of supported programming languages.

        Returns:
            List of language names
        """
        return [lang.value for lang in ProgrammingLanguage]

    def get_difficulty_levels(self) -> List[str]:
        """
        Get list of difficulty levels.

        Returns:
            List of difficulty level names
        """
        return [level.value for level in DifficultyLevel]

    def is_ai_available(self) -> bool:
        """
        Check if AI lesson generation is available.

        Returns:
            True if Claude client is configured
        """
        return self.claude_client is not None and self.claude_client.is_configured()
