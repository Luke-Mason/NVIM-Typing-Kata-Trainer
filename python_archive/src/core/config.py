"""Configuration management for the application."""
import os
from pathlib import Path
from typing import Optional, List
from dataclasses import dataclass, field
from dotenv import load_dotenv

from .constants import (
    DEFAULT_EXIT_SEQUENCE,
    AI_FEEDBACK_END_SESSION,
    AI_FEEDBACK_AFTER_EACH,
    AI_FEEDBACK_NONE,
)


@dataclass
class Config:
    """Application configuration."""

    # API Configuration
    claude_api_key: str

    # Vimrc Paths
    vimrc_path: Optional[Path] = None
    detected_vimrc_paths: List[Path] = field(default_factory=list)

    # Neovim Config Path
    nvim_config_dir: Optional[Path] = None

    # Game Settings
    universal_exit_sequence: str = DEFAULT_EXIT_SEQUENCE
    ai_feedback_timing: str = AI_FEEDBACK_END_SESSION

    # Display Settings
    theme: str = "default"

    # Paths
    progress_dir: Path = Path("progress")
    data_dir: Path = Path("data")

    @classmethod
    def from_env(cls) -> 'Config':
        """
        Load configuration from environment variables.

        Returns:
            Config instance populated from .env file and environment

        Raises:
            ValueError: If required configuration is missing
        """
        # Load .env file if it exists
        load_dotenv()

        # Get API key (required)
        api_key = os.getenv('CLAUDE_API_KEY', '')
        if not api_key:
            raise ValueError(
                "CLAUDE_API_KEY not found in environment. "
                "Create a .env file with your API key or set the environment variable."
            )

        # Get optional configuration
        exit_sequence = os.getenv('UNIVERSAL_EXIT_SEQUENCE', DEFAULT_EXIT_SEQUENCE)
        ai_feedback = os.getenv('AI_FEEDBACK_TIMING', AI_FEEDBACK_END_SESSION)

        # Validate AI feedback timing
        valid_timings = [AI_FEEDBACK_AFTER_EACH, AI_FEEDBACK_END_SESSION, AI_FEEDBACK_NONE]
        if ai_feedback not in valid_timings:
            print(f"Warning: Invalid AI_FEEDBACK_TIMING '{ai_feedback}'. Using default: {AI_FEEDBACK_END_SESSION}")
            ai_feedback = AI_FEEDBACK_END_SESSION

        theme = os.getenv('THEME', 'default')
        progress_dir = Path(os.getenv('PROGRESS_DIR', 'progress'))
        data_dir = Path(os.getenv('DATA_DIR', 'data'))

        # Auto-detect vimrc paths
        detected_paths = cls._detect_vimrc_paths()

        # Check if user specified a custom path
        custom_vimrc = os.getenv('VIMRC_PATH')
        vimrc_path = None
        if custom_vimrc:
            custom_path = Path(custom_vimrc)
            if custom_path.exists():
                vimrc_path = custom_path
            else:
                print(f"Warning: Specified VIMRC_PATH does not exist: {custom_path}")

        # If no custom path, use the first detected path
        if vimrc_path is None and detected_paths:
            vimrc_path = detected_paths[0]

        # Auto-detect Neovim config directory
        nvim_config_dir = cls._detect_nvim_config_dir()

        # Check for custom Neovim config path
        custom_nvim = os.getenv('NVIM_CONFIG_DIR')
        if custom_nvim:
            custom_nvim_path = Path(custom_nvim)
            if custom_nvim_path.exists():
                nvim_config_dir = custom_nvim_path
            else:
                print(f"Warning: Specified NVIM_CONFIG_DIR does not exist: {custom_nvim_path}")

        return cls(
            claude_api_key=api_key,
            vimrc_path=vimrc_path,
            detected_vimrc_paths=detected_paths,
            nvim_config_dir=nvim_config_dir,
            universal_exit_sequence=exit_sequence,
            ai_feedback_timing=ai_feedback,
            theme=theme,
            progress_dir=progress_dir,
            data_dir=data_dir,
        )

    @staticmethod
    def _detect_vimrc_paths() -> List[Path]:
        """
        Auto-detect vimrc file paths on the system.

        Returns:
            List of Path objects for found vimrc files (in priority order)
        """
        possible_paths = []

        # Get home directory
        home = Path.home()

        # Windows paths
        if os.name == 'nt':
            possible_paths.extend([
                home / '_vimrc',  # Traditional Windows vim
                home / '.vimrc',  # Unix-style on Windows
                Path(os.getenv('LOCALAPPDATA', '')) / 'nvim' / 'init.vim',  # Neovim Windows
                Path(os.getenv('LOCALAPPDATA', '')) / 'nvim' / 'init.lua',  # Neovim lua config
                home / 'AppData' / 'Local' / 'nvim' / 'init.vim',
                home / 'AppData' / 'Local' / 'nvim' / 'init.lua',
            ])

        # Unix/Linux/Mac paths
        possible_paths.extend([
            home / '.vimrc',  # Traditional vim
            home / '.vim' / 'vimrc',  # Alternative location
            home / '.config' / 'nvim' / 'init.vim',  # Neovim
            home / '.config' / 'nvim' / 'init.lua',  # Neovim lua config
        ])

        # Filter to only existing paths
        existing_paths = [p for p in possible_paths if p.exists() and p.is_file()]

        return existing_paths

    @staticmethod
    def _detect_nvim_config_dir() -> Optional[Path]:
        """
        Auto-detect Neovim config directory.

        Returns:
            Path to Neovim config directory if found
        """
        home = Path.home()

        # Possible Neovim config locations
        possible_paths = [
            home / '.config' / 'nvim',  # Unix/Linux/Mac
            home / 'AppData' / 'Local' / 'nvim',  # Windows
            Path(os.getenv('LOCALAPPDATA', '')) / 'nvim',  # Windows with LOCALAPPDATA
            Path(os.getenv('XDG_CONFIG_HOME', home / '.config')) / 'nvim',  # XDG standard
        ]

        # Return first existing directory
        for path in possible_paths:
            if path.exists() and path.is_dir():
                # Check if it has Lua files (indicates it's a real config)
                if list(path.glob('*.lua')) or list(path.glob('**/*.lua')):
                    return path

        return None

    def ensure_directories(self):
        """Create necessary directories if they don't exist."""
        self.progress_dir.mkdir(parents=True, exist_ok=True)
        self.data_dir.mkdir(parents=True, exist_ok=True)

    def validate(self) -> List[str]:
        """
        Validate the configuration.

        Returns:
            List of warning messages (empty if all OK)
        """
        warnings = []

        if not self.claude_api_key:
            warnings.append("CLAUDE_API_KEY is not set")

        if self.vimrc_path is None and self.nvim_config_dir is None:
            warnings.append("No vimrc or Neovim config detected. Custom keybinding training will use fallback keymaps.")
        else:
            if self.vimrc_path and not self.vimrc_path.exists():
                warnings.append(f"Configured vimrc path does not exist: {self.vimrc_path}")
            if self.nvim_config_dir and not self.nvim_config_dir.exists():
                warnings.append(f"Configured Neovim path does not exist: {self.nvim_config_dir}")

        return warnings

    def has_vim_config(self) -> bool:
        """Check if any vim/neovim configuration is available."""
        return self.vimrc_path is not None or self.nvim_config_dir is not None

    def __str__(self) -> str:
        """String representation of config (safe - doesn't show API key)."""
        vimrc_status = str(self.vimrc_path) if self.vimrc_path else "Not found"
        nvim_status = str(self.nvim_config_dir) if self.nvim_config_dir else "Not found"

        return f"""Configuration:
  API Key: {'Set' if self.claude_api_key else 'NOT SET'}
  Vimrc: {vimrc_status}
  Neovim Config: {nvim_status}
  Exit Sequence: {self.universal_exit_sequence}
  AI Feedback: {self.ai_feedback_timing}
  Progress Dir: {self.progress_dir}
  Theme: {self.theme}
"""
