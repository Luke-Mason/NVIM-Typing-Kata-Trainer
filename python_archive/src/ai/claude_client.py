"""Claude AI client for lesson generation and keystroke analysis."""
import asyncio
from typing import Optional, Dict, Any, List
from anthropic import Anthropic, AsyncAnthropic
from anthropic.types import Message

from ..core.config import Config


class ClaudeClient:
    """Client for interacting with Claude AI API."""

    def __init__(self, config: Config):
        """
        Initialize Claude client.

        Args:
            config: Application configuration containing API key
        """
        self.config = config
        self.api_key = config.claude_api_key

        if not self.api_key:
            raise ValueError("CLAUDE_API_KEY not set in configuration")

        # Initialize clients
        self.client = Anthropic(api_key=self.api_key)
        self.async_client = AsyncAnthropic(api_key=self.api_key)

        # Model configuration
        self.model = "claude-sonnet-4-20250514"  # Latest model
        self.max_tokens = 4096
        self.temperature = 0.7

    async def generate_completion(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
    ) -> str:
        """
        Generate a completion from Claude.

        Args:
            prompt: User prompt
            system_prompt: Optional system prompt
            temperature: Optional temperature override
            max_tokens: Optional max tokens override

        Returns:
            Generated text response
        """
        try:
            message = await self.async_client.messages.create(
                model=self.model,
                max_tokens=max_tokens or self.max_tokens,
                temperature=temperature or self.temperature,
                system=system_prompt or "",
                messages=[
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            )

            # Extract text from response
            if message.content and len(message.content) > 0:
                return message.content[0].text

            return ""

        except Exception as e:
            raise RuntimeError(f"Failed to generate completion: {e}")

    def generate_completion_sync(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
    ) -> str:
        """
        Synchronous version of generate_completion.

        Args:
            prompt: User prompt
            system_prompt: Optional system prompt
            temperature: Optional temperature override
            max_tokens: Optional max tokens override

        Returns:
            Generated text response
        """
        try:
            message = self.client.messages.create(
                model=self.model,
                max_tokens=max_tokens or self.max_tokens,
                temperature=temperature or self.temperature,
                system=system_prompt or "",
                messages=[
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            )

            # Extract text from response
            if message.content and len(message.content) > 0:
                return message.content[0].text

            return ""

        except Exception as e:
            raise RuntimeError(f"Failed to generate completion: {e}")

    async def analyze_keystrokes(
        self,
        keystrokes: List[Dict[str, Any]],
        task_description: str,
        vimrc_config: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Analyze a sequence of keystrokes for efficiency.

        Args:
            keystrokes: List of keystroke records
            task_description: Description of what the user was trying to do
            vimrc_config: Optional vimrc configuration context

        Returns:
            Analysis results with suggestions
        """
        # Format keystrokes for Claude
        keystroke_str = self._format_keystrokes(keystrokes)

        system_prompt = """You are an expert vim user and teacher. Analyze keystroke sequences
and provide constructive feedback on efficiency, suggesting better vim commands or motions."""

        prompt = f"""Analyze these vim keystrokes:

Task: {task_description}

Keystrokes:
{keystroke_str}

{f'User vimrc config: {vimrc_config}' if vimrc_config else ''}

Provide:
1. Efficiency rating (1-10)
2. Alternative approaches (if any)
3. Specific suggestions for improvement
4. Praise for good practices

Keep feedback concise and actionable."""

        response = await self.generate_completion(
            prompt=prompt,
            system_prompt=system_prompt,
            temperature=0.5  # Lower temperature for more consistent analysis
        )

        # Parse response into structured format
        return {
            "analysis": response,
            "keystroke_count": len(keystrokes),
            "task": task_description
        }

    async def generate_coding_lesson(
        self,
        language: str,
        difficulty: str = "beginner",
        topic: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Generate a coding lesson for practice.

        Args:
            language: Programming language (python, javascript, etc.)
            difficulty: Difficulty level (beginner, intermediate, advanced)
            topic: Optional specific topic to focus on

        Returns:
            Lesson data with code and instructions
        """
        system_prompt = f"""You are a programming instructor creating vim typing lessons.
Generate realistic {language} code snippets for typing practice."""

        prompt = f"""Create a {difficulty}-level {language} coding lesson{f' about {topic}' if topic else ''}.

Requirements:
1. Realistic, properly formatted code (5-15 lines)
2. Include variety: functions, variables, control flow, comments
3. Use common patterns from actual {language} projects
4. Appropriate difficulty for {difficulty} level

Provide:
1. Code snippet
2. Brief description of what the code does
3. Key vim movements to practice (e.g., 'w', 'b', 'f', '$', etc.)

Format as:
```{language}
[code here]
```

Description: [description]
Practice: [movements]"""

        response = await self.generate_completion(
            prompt=prompt,
            system_prompt=system_prompt,
            temperature=0.8  # Higher temperature for variety
        )

        # Parse response
        code = self._extract_code_block(response)
        description = self._extract_description(response)
        practice_movements = self._extract_practice(response)

        return {
            "code": code,
            "description": description,
            "practice_movements": practice_movements,
            "language": language,
            "difficulty": difficulty,
            "raw_response": response
        }

    def _format_keystrokes(self, keystrokes: List[Dict[str, Any]]) -> str:
        """Format keystrokes for display."""
        lines = []
        for i, ks in enumerate(keystrokes, 1):
            key = ks.get('key', '?')
            timestamp = ks.get('timestamp', 0)
            lines.append(f"{i}. {key} (t={timestamp:.3f}s)")
        return "\n".join(lines)

    def _extract_code_block(self, text: str) -> str:
        """Extract code from markdown code block."""
        import re
        pattern = r"```[\w]*\n(.*?)\n```"
        match = re.search(pattern, text, re.DOTALL)
        if match:
            return match.group(1).strip()
        return text.strip()

    def _extract_description(self, text: str) -> str:
        """Extract description from response."""
        import re
        pattern = r"Description:\s*(.+?)(?=\n\w+:|$)"
        match = re.search(pattern, text, re.DOTALL)
        if match:
            return match.group(1).strip()
        return ""

    def _extract_practice(self, text: str) -> str:
        """Extract practice movements from response."""
        import re
        pattern = r"Practice:\s*(.+?)(?=\n\w+:|$)"
        match = re.search(pattern, text, re.DOTALL)
        if match:
            return match.group(1).strip()
        return ""

    async def get_feedback_for_session(
        self,
        session_data: Dict[str, Any],
        mode_name: str
    ) -> str:
        """
        Get AI feedback for a completed session.

        Args:
            session_data: Session statistics and data
            mode_name: Name of the game mode

        Returns:
            Personalized feedback message
        """
        system_prompt = """You are a supportive vim training coach. Provide encouraging
feedback on training sessions with specific praise and gentle suggestions."""

        prompt = f"""Review this {mode_name} training session:

Tasks Completed: {session_data.get('tasks_completed', 0)}
Accuracy: {session_data.get('accuracy', 0):.1f}%
Best Streak: {session_data.get('best_streak', 0)}
XP Earned: {session_data.get('xp_earned', 0):,}
Duration: {session_data.get('duration', 0)}s

Provide brief, encouraging feedback (2-3 sentences) with:
1. Praise for accomplishments
2. One specific area to focus on next time
3. Motivational closing"""

        return await self.generate_completion(
            prompt=prompt,
            system_prompt=system_prompt,
            temperature=0.7,
            max_tokens=200
        )

    def is_configured(self) -> bool:
        """Check if Claude client is properly configured."""
        return bool(self.api_key)
