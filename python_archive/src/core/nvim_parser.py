"""Parser for Neovim Lua configurations to extract keybindings."""
import re
from pathlib import Path
from typing import List, Dict, Optional, Set, Tuple
from dataclasses import dataclass, field


@dataclass
class NvimKeymap:
    """Represents a Neovim keybinding."""
    mode: str  # n, i, v, x, etc. or list like 'n,v'
    lhs: str  # Left-hand side (keys to press)
    rhs: str  # Right-hand side (what happens)
    description: Optional[str] = None
    plugin: Optional[str] = None  # Plugin that defines this keymap
    source_file: Optional[str] = None  # File where it was defined
    options: Dict[str, any] = field(default_factory=dict)  # noremap, silent, etc.

    def __str__(self) -> str:
        """String representation."""
        desc = f" -- {self.description}" if self.description else ""
        plugin_info = f" [{self.plugin}]" if self.plugin else ""
        return f"{self.mode}: {self.lhs} → {self.rhs}{desc}{plugin_info}"


@dataclass
class PluginConfig:
    """Represents a plugin and its configuration."""
    name: str
    url: Optional[str] = None
    keymaps: List[NvimKeymap] = field(default_factory=list)
    enabled: bool = True
    lazy: bool = False


class NvimConfigParser:
    """Parser for Neovim Lua configuration files."""

    # Patterns for different keymap syntaxes
    KEYMAP_PATTERNS = [
        # vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = 'Find Files' })
        r"vim\.keymap\.set\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*(?:,\s*\{([^}]*)\})?\s*\)",

        # vim.api.nvim_set_keymap('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { noremap = true })
        r"vim\.api\.nvim_set_keymap\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*(?:,\s*\{([^}]*)\})?\s*\)",

        # map('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
        r"(?:^|\s)map\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*(?:,\s*\{([^}]*)\})?\s*\)",
    ]

    # Patterns for plugin managers
    LAZY_NVIM_PATTERN = r"[\'\"]([^\'\"]+/[^\'\"]+)[\'\"]"  # 'username/plugin'
    PACKER_USE_PATTERN = r"use\s*[\'\"]([^\'\"]+)[\'\"]"
    PACKER_USE_TABLE_PATTERN = r"use\s*\{[^}]*[\'\"]([^\'\"]+)[\'\"]"

    def __init__(self, nvim_config_dir: Optional[Path] = None):
        """
        Initialize Neovim config parser.

        Args:
            nvim_config_dir: Path to Neovim config directory (default: ~/.config/nvim)
        """
        if nvim_config_dir is None:
            home = Path.home()
            # Try common Neovim config locations
            possible_paths = [
                home / '.config' / 'nvim',
                home / 'AppData' / 'Local' / 'nvim',  # Windows
                home / '.nvim',
            ]
            for path in possible_paths:
                if path.exists():
                    nvim_config_dir = path
                    break

        self.config_dir = nvim_config_dir
        self.keymaps: List[NvimKeymap] = []
        self.plugins: Dict[str, PluginConfig] = {}
        self.leader_key: str = '\\'  # Default
        self.localleader_key: str = '\\'  # Default

    def parse(self) -> bool:
        """
        Parse the Neovim configuration.

        Returns:
            True if parsing was successful
        """
        if not self.config_dir or not self.config_dir.exists():
            return False

        try:
            # Find all Lua files
            lua_files = list(self.config_dir.rglob('*.lua'))

            # Parse init.lua first (for leader key)
            init_file = self.config_dir / 'init.lua'
            if init_file.exists():
                self._parse_file(init_file)

            # Parse all other Lua files
            for lua_file in lua_files:
                if lua_file != init_file:
                    self._parse_file(lua_file)

            return True

        except Exception as e:
            print(f"Error parsing Neovim config: {e}")
            return False

    def _parse_file(self, file_path: Path):
        """
        Parse a single Lua file.

        Args:
            file_path: Path to Lua file
        """
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')

            # Extract leader key
            self._extract_leader_keys(content)

            # Extract keymaps
            self._extract_keymaps(content, str(file_path))

            # Extract plugins
            self._extract_plugins(content, str(file_path))

        except Exception as e:
            print(f"Error parsing {file_path}: {e}")

    def _extract_leader_keys(self, content: str):
        """Extract leader and localleader keys."""
        # vim.g.mapleader = " "
        leader_match = re.search(r"vim\.g\.mapleader\s*=\s*['\"](.)['\"]", content)
        if leader_match:
            self.leader_key = leader_match.group(1)

        # vim.g.maplocalleader = ","
        localleader_match = re.search(r"vim\.g\.maplocalleader\s*=\s*['\"](.)['\"]", content)
        if localleader_match:
            self.localleader_key = localleader_match.group(1)

    def _extract_keymaps(self, content: str, source_file: str):
        """Extract keymaps from Lua content."""
        for pattern in self.KEYMAP_PATTERNS:
            matches = re.finditer(pattern, content, re.MULTILINE)
            for match in matches:
                mode = match.group(1)
                lhs = match.group(2)
                rhs = match.group(3)
                options_str = match.group(4) if len(match.groups()) >= 4 else None

                # Parse options
                options = {}
                description = None
                if options_str:
                    options, description = self._parse_options(options_str)

                # Replace <leader> with actual leader key
                lhs = lhs.replace('<leader>', f'<leader:{self.leader_key}>')
                lhs = lhs.replace('<localleader>', f'<localleader:{self.localleader_key}>')

                keymap = NvimKeymap(
                    mode=mode,
                    lhs=lhs,
                    rhs=rhs,
                    description=description,
                    source_file=source_file,
                    options=options
                )
                self.keymaps.append(keymap)

        # Also look for which-key.nvim registrations
        self._extract_which_key_mappings(content, source_file)

    def _parse_options(self, options_str: str) -> Tuple[Dict, Optional[str]]:
        """
        Parse options table.

        Args:
            options_str: String containing Lua table options

        Returns:
            Tuple of (options dict, description)
        """
        options = {}
        description = None

        # Extract desc
        desc_match = re.search(r"desc\s*=\s*['\"]([^'\"]+)['\"]", options_str)
        if desc_match:
            description = desc_match.group(1)

        # Extract boolean options
        for opt in ['noremap', 'silent', 'expr', 'nowait']:
            if re.search(rf"{opt}\s*=\s*true", options_str):
                options[opt] = True

        return options, description

    def _extract_which_key_mappings(self, content: str, source_file: str):
        """Extract which-key.nvim style mappings."""
        # which-key.register({ ['<leader>f'] = { name = '+file', ... } })
        # This is complex, so we'll do a simple extraction
        wk_pattern = r"\['(<[^>]+>|[^']+)'\]\s*=\s*\{\s*name\s*=\s*['\"]([^'\"]+)['\"]"
        matches = re.finditer(wk_pattern, content)
        for match in matches:
            lhs = match.group(1)
            desc = match.group(2)

            # Replace leader
            lhs = lhs.replace('<leader>', f'<leader:{self.leader_key}>')

            keymap = NvimKeymap(
                mode='n',  # which-key typically uses normal mode
                lhs=lhs,
                rhs='[which-key group]',
                description=desc,
                source_file=source_file,
                plugin='which-key.nvim'
            )
            self.keymaps.append(keymap)

    def _extract_plugins(self, content: str, source_file: str):
        """Extract plugin configurations."""
        # lazy.nvim style
        lazy_matches = re.finditer(self.LAZY_NVIM_PATTERN, content)
        for match in matches:
            plugin_name = match.group(1).split('/')[-1]
            if plugin_name not in self.plugins:
                self.plugins[plugin_name] = PluginConfig(
                    name=plugin_name,
                    url=match.group(1)
                )

        # packer.nvim style
        packer_matches = re.finditer(self.PACKER_USE_PATTERN, content)
        for match in packer_matches:
            plugin_name = match.group(1).split('/')[-1]
            if plugin_name not in self.plugins:
                self.plugins[plugin_name] = PluginConfig(
                    name=plugin_name,
                    url=match.group(1)
                )

        # Extract plugin-specific keymaps (if defined in keys = {})
        self._extract_plugin_keymaps(content, source_file)

    def _extract_plugin_keymaps(self, content: str, source_file: str):
        """Extract keymaps defined in plugin specifications."""
        # lazy.nvim keys = { { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find Files' } }
        plugin_keymap_pattern = r"keys\s*=\s*\{([^}]+)\}"
        matches = re.finditer(plugin_keymap_pattern, content, re.DOTALL)

        for match in matches:
            keys_content = match.group(1)
            # Extract individual key definitions
            key_pattern = r"\{\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*(?:,\s*desc\s*=\s*['\"]([^'\"]+)['\"])?"
            key_matches = re.finditer(key_pattern, keys_content)

            for key_match in key_matches:
                lhs = key_match.group(1)
                rhs = key_match.group(2)
                desc = key_match.group(3) if len(key_match.groups()) >= 3 else None

                lhs = lhs.replace('<leader>', f'<leader:{self.leader_key}>')

                keymap = NvimKeymap(
                    mode='n',
                    lhs=lhs,
                    rhs=rhs,
                    description=desc,
                    source_file=source_file
                )
                self.keymaps.append(keymap)

    def get_keymaps(self, mode: Optional[str] = None) -> List[NvimKeymap]:
        """
        Get all keymaps, optionally filtered by mode.

        Args:
            mode: Optional mode to filter by

        Returns:
            List of NvimKeymap objects
        """
        if mode is None:
            return self.keymaps

        return [km for km in self.keymaps if mode in km.mode]

    def get_leader_key(self) -> str:
        """Get the leader key."""
        return self.leader_key

    def get_localleader_key(self) -> str:
        """Get the local leader key."""
        return self.localleader_key

    def get_plugins(self) -> List[PluginConfig]:
        """Get list of detected plugins."""
        return list(self.plugins.values())

    def get_keymaps_summary(self) -> str:
        """
        Generate a summary of keymaps for AI context.

        Returns:
            Formatted summary string
        """
        if not self.keymaps:
            return "No custom keymaps found in Neovim configuration"

        lines = [
            f"Neovim Configuration Summary",
            f"Leader key: {self.leader_key}",
            f"Local leader key: {self.localleader_key}",
            f"Total keymaps: {len(self.keymaps)}",
            f"Detected plugins: {len(self.plugins)}",
            ""
        ]

        # Group by mode
        by_mode: Dict[str, List[NvimKeymap]] = {}
        for keymap in self.keymaps:
            modes = keymap.mode.split(',')
            for mode in modes:
                mode = mode.strip()
                if mode not in by_mode:
                    by_mode[mode] = []
                by_mode[mode].append(keymap)

        # Format by mode
        mode_names = {
            'n': 'Normal',
            'i': 'Insert',
            'v': 'Visual',
            'x': 'Visual Block',
            'c': 'Command',
            't': 'Terminal',
            's': 'Select'
        }

        for mode, keymaps in sorted(by_mode.items()):
            mode_name = mode_names.get(mode, mode)
            lines.append(f"{mode_name} mode ({len(keymaps)} keymaps):")

            # Show up to 15 keymaps per mode
            for keymap in keymaps[:15]:
                desc = f" -- {keymap.description}" if keymap.description else ""
                plugin = f" [{keymap.plugin}]" if keymap.plugin else ""
                lines.append(f"  {keymap.lhs} → {keymap.rhs}{desc}{plugin}")

            if len(keymaps) > 15:
                lines.append(f"  ... and {len(keymaps) - 15} more")

            lines.append("")

        # Add plugin list
        if self.plugins:
            lines.append("Detected Plugins:")
            for plugin in list(self.plugins.values())[:20]:
                lines.append(f"  - {plugin.name}")
            if len(self.plugins) > 20:
                lines.append(f"  ... and {len(self.plugins) - 20} more")

        return "\n".join(lines)

    def get_statistics(self) -> Dict[str, int]:
        """
        Get statistics about the configuration.

        Returns:
            Dictionary with statistics
        """
        mode_counts = {}
        for keymap in self.keymaps:
            modes = keymap.mode.split(',')
            for mode in modes:
                mode = mode.strip()
                mode_counts[mode] = mode_counts.get(mode, 0) + 1

        return {
            'total_keymaps': len(self.keymaps),
            'total_plugins': len(self.plugins),
            'normal_mode_keymaps': mode_counts.get('n', 0),
            'insert_mode_keymaps': mode_counts.get('i', 0),
            'visual_mode_keymaps': mode_counts.get('v', 0),
            'leader_keymaps': len([km for km in self.keymaps if '<leader' in km.lhs]),
        }

    def search_keymaps(self, query: str) -> List[NvimKeymap]:
        """
        Search keymaps by description or key.

        Args:
            query: Search query

        Returns:
            List of matching keymaps
        """
        query_lower = query.lower()
        results = []

        for keymap in self.keymaps:
            if query_lower in keymap.lhs.lower():
                results.append(keymap)
            elif keymap.description and query_lower in keymap.description.lower():
                results.append(keymap)
            elif keymap.rhs and query_lower in keymap.rhs.lower():
                results.append(keymap)

        return results

    def has_plugin(self, plugin_name: str) -> bool:
        """Check if a plugin is detected."""
        plugin_name_lower = plugin_name.lower()
        return any(plugin_name_lower in name.lower() for name in self.plugins.keys())

    def get_custom_training_keymaps(self) -> List[NvimKeymap]:
        """
        Get keymaps suitable for training (user-defined, commonly used).

        Returns:
            List of keymaps good for practice
        """
        # Filter out very complex keymaps and focus on common user patterns
        training_keymaps = []

        for keymap in self.keymaps:
            # Include leader keymaps (most common custom bindings)
            if '<leader' in keymap.lhs:
                training_keymaps.append(keymap)
            # Include short custom bindings
            elif len(keymap.lhs) <= 3 and not keymap.lhs.startswith('<'):
                training_keymaps.append(keymap)

        return training_keymaps
