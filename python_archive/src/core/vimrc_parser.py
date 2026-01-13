"""Parser for vimrc files to extract keybindings and configuration."""
import re
from typing import List, Dict, Optional, Tuple
from pathlib import Path
from dataclasses import dataclass


@dataclass
class KeyMapping:
    """Represents a vim key mapping."""
    mode: str  # n, i, v, x, etc.
    from_keys: str  # Keys that trigger the mapping
    to_keys: str  # Keys that are executed
    options: List[str]  # Options like <silent>, <expr>, etc.
    line_number: int  # Line number in vimrc
    comment: Optional[str] = None  # Comment if present


class VimrcParser:
    """Parser for vimrc files."""

    # Map mode commands
    MAP_COMMANDS = {
        'map': ['n', 'v', 'x', 'o'],  # Normal, Visual, Select, Operator-pending
        'nmap': ['n'],  # Normal
        'imap': ['i'],  # Insert
        'vmap': ['v', 'x'],  # Visual and Select
        'xmap': ['x'],  # Visual
        'smap': ['s'],  # Select
        'cmap': ['c'],  # Command-line
        'omap': ['o'],  # Operator-pending
        'tmap': ['t'],  # Terminal
        'lmap': ['l'],  # Language-Argument
        'noremap': ['n', 'v', 'x', 'o'],  # Non-recursive map
        'nnoremap': ['n'],  # Non-recursive normal
        'inoremap': ['i'],  # Non-recursive insert
        'vnoremap': ['v', 'x'],  # Non-recursive visual
        'xnoremap': ['x'],  # Non-recursive visual
        'snoremap': ['s'],  # Non-recursive select
        'cnoremap': ['c'],  # Non-recursive command-line
        'onoremap': ['o'],  # Non-recursive operator-pending
        'tnoremap': ['t'],  # Non-recursive terminal
        'lnoremap': ['l'],  # Non-recursive language-argument
    }

    # Special key options
    MAP_OPTIONS = ['<silent>', '<expr>', '<buffer>', '<nowait>', '<script>', '<unique>', '<special>']

    def __init__(self, vimrc_path: Optional[str] = None):
        """
        Initialize vimrc parser.

        Args:
            vimrc_path: Path to vimrc file
        """
        self.vimrc_path = vimrc_path
        self.mappings: List[KeyMapping] = []
        self.raw_content: str = ""
        self.settings: Dict[str, str] = {}

    def parse(self, vimrc_path: Optional[str] = None) -> bool:
        """
        Parse a vimrc file.

        Args:
            vimrc_path: Path to vimrc file (uses instance path if not provided)

        Returns:
            True if parsing was successful
        """
        path = vimrc_path or self.vimrc_path

        if not path:
            return False

        try:
            vimrc_file = Path(path)
            if not vimrc_file.exists():
                return False

            self.raw_content = vimrc_file.read_text(encoding='utf-8', errors='ignore')
            self._parse_content()
            return True

        except Exception as e:
            print(f"Error parsing vimrc: {e}")
            return False

    def _parse_content(self):
        """Parse the raw vimrc content."""
        lines = self.raw_content.split('\n')

        for line_num, line in enumerate(lines, 1):
            # Remove leading/trailing whitespace
            line = line.strip()

            # Skip empty lines and comments
            if not line or line.startswith('"'):
                continue

            # Check for mapping commands
            mapping = self._parse_mapping_line(line, line_num)
            if mapping:
                self.mappings.append(mapping)
                continue

            # Parse settings
            self._parse_setting_line(line)

    def _parse_mapping_line(self, line: str, line_num: int) -> Optional[KeyMapping]:
        """
        Parse a single line for key mappings.

        Args:
            line: Line to parse
            line_num: Line number in file

        Returns:
            KeyMapping if found, None otherwise
        """
        # Extract comment if present
        comment = None
        if '"' in line:
            parts = line.split('"', 1)
            line = parts[0].strip()
            comment = parts[1].strip() if len(parts) > 1 else None

        # Check for map commands
        for cmd, modes in self.MAP_COMMANDS.items():
            pattern = rf'\b{cmd}\b'
            if re.search(pattern, line):
                # Extract the mapping
                result = self._extract_mapping(line, cmd, modes, line_num, comment)
                if result:
                    return result

        return None

    def _extract_mapping(
        self,
        line: str,
        command: str,
        modes: List[str],
        line_num: int,
        comment: Optional[str]
    ) -> Optional[KeyMapping]:
        """
        Extract mapping details from a line.

        Args:
            line: Line containing mapping
            command: Map command (nmap, etc.)
            modes: Modes this command applies to
            line_num: Line number
            comment: Comment if present

        Returns:
            KeyMapping if successfully extracted
        """
        # Remove the command
        remaining = re.sub(rf'\b{command}\b', '', line, count=1).strip()

        if not remaining:
            return None

        # Extract options
        options = []
        for opt in self.MAP_OPTIONS:
            if opt in remaining:
                options.append(opt)
                remaining = remaining.replace(opt, '').strip()

        # Split remaining into from_keys and to_keys
        parts = remaining.split(None, 1)
        if len(parts) < 2:
            return None

        from_keys = parts[0]
        to_keys = parts[1]

        return KeyMapping(
            mode=','.join(modes),
            from_keys=from_keys,
            to_keys=to_keys,
            options=options,
            line_number=line_num,
            comment=comment
        )

    def _parse_setting_line(self, line: str):
        """
        Parse a line for vim settings.

        Args:
            line: Line to parse
        """
        # Look for set commands
        set_pattern = r'\bset\b\s+([a-zA-Z]+)(?:=([^\s]+))?'
        match = re.search(set_pattern, line)
        if match:
            setting = match.group(1)
            value = match.group(2) if match.group(2) else 'on'
            self.settings[setting] = value

    def get_mappings(self, mode: Optional[str] = None) -> List[KeyMapping]:
        """
        Get all mappings, optionally filtered by mode.

        Args:
            mode: Optional mode to filter by (n, i, v, etc.)

        Returns:
            List of KeyMapping objects
        """
        if mode is None:
            return self.mappings

        return [m for m in self.mappings if mode in m.mode]

    def get_leader_key(self) -> str:
        """
        Get the leader key setting.

        Returns:
            Leader key (default: backslash)
        """
        # Look for mapleader in settings
        for line in self.raw_content.split('\n'):
            if 'mapleader' in line.lower():
                # Extract the leader key
                match = re.search(r'["\'](.)["\']', line)
                if match:
                    return match.group(1)

        return '\\'  # Default vim leader

    def get_custom_keybindings_summary(self) -> str:
        """
        Get a summary of custom keybindings for AI context.

        Returns:
            Formatted summary string
        """
        if not self.mappings:
            return "No custom keybindings found"

        summary_lines = [f"Leader key: {self.get_leader_key()}", ""]

        # Group by mode
        by_mode: Dict[str, List[KeyMapping]] = {}
        for mapping in self.mappings:
            for mode in mapping.mode.split(','):
                if mode not in by_mode:
                    by_mode[mode] = []
                by_mode[mode].append(mapping)

        # Format by mode
        mode_names = {
            'n': 'Normal',
            'i': 'Insert',
            'v': 'Visual',
            'x': 'Visual',
            'c': 'Command',
            'o': 'Operator',
            't': 'Terminal'
        }

        for mode, mappings in sorted(by_mode.items()):
            mode_name = mode_names.get(mode, mode)
            summary_lines.append(f"{mode_name} mode:")

            # Show first 10 mappings per mode
            for mapping in mappings[:10]:
                comment_str = f" -- {mapping.comment}" if mapping.comment else ""
                summary_lines.append(f"  {mapping.from_keys} → {mapping.to_keys}{comment_str}")

            if len(mappings) > 10:
                summary_lines.append(f"  ... and {len(mappings) - 10} more")

            summary_lines.append("")

        return "\n".join(summary_lines)

    def has_mappings(self) -> bool:
        """Check if any mappings were found."""
        return len(self.mappings) > 0

    def get_statistics(self) -> Dict[str, int]:
        """
        Get statistics about the vimrc file.

        Returns:
            Dictionary with statistics
        """
        return {
            "total_mappings": len(self.mappings),
            "normal_mode_mappings": len(self.get_mappings('n')),
            "insert_mode_mappings": len(self.get_mappings('i')),
            "visual_mode_mappings": len(self.get_mappings('v')),
            "total_settings": len(self.settings),
            "total_lines": len(self.raw_content.split('\n'))
        }
