"""Keyboard input handling using pynput."""
from typing import Optional, Callable, Set
from dataclasses import dataclass
from pynput import keyboard


@dataclass
class KeyEvent:
    """Represents a keyboard event."""
    key: keyboard.Key | keyboard.KeyCode | None
    char: Optional[str]
    modifiers: Set[str]
    key_name: str  # Human-readable key name

    def matches(self, target: str) -> bool:
        """
        Check if this event matches a target key string.

        Args:
            target: Target string like "Ctrl+W", "F1", "a", etc.

        Returns:
            True if matches, False otherwise
        """
        target = target.lower()

        # Check for modifier combinations
        if '+' in target:
            parts = target.split('+')
            required_mods = set(parts[:-1])
            key_part = parts[-1]

            # Check if all required modifiers are present
            if not required_mods.issubset(self.modifiers):
                return False

            # Check the key part
            return self.key_name.lower() == key_part

        # Simple key match
        return self.key_name.lower() == target.lower()

    def __str__(self) -> str:
        """String representation."""
        if self.modifiers:
            mods = '+'.join(sorted(self.modifiers))
            return f"{mods}+{self.key_name}"
        return self.key_name


class KeyboardHandler:
    """Handles keyboard input capture using pynput."""

    def __init__(self, callback: Callable[[KeyEvent], None]):
        """
        Initialize keyboard handler.

        Args:
            callback: Function to call when a key is pressed
        """
        self.callback = callback
        self.listener: Optional[keyboard.Listener] = None
        self.current_modifiers: Set[str] = set()

    def start(self):
        """Start listening to keyboard events."""
        if self.listener is not None:
            return  # Already started

        self.listener = keyboard.Listener(
            on_press=self._on_press,
            on_release=self._on_release
        )
        self.listener.start()

    def stop(self):
        """Stop listening to keyboard events."""
        if self.listener is not None:
            self.listener.stop()
            self.listener = None
            self.current_modifiers.clear()

    def _on_press(self, key):
        """Handle key press event."""
        # Track modifiers
        if key in [keyboard.Key.ctrl, keyboard.Key.ctrl_l, keyboard.Key.ctrl_r]:
            self.current_modifiers.add('ctrl')
        elif key in [keyboard.Key.shift, keyboard.Key.shift_l, keyboard.Key.shift_r]:
            self.current_modifiers.add('shift')
        elif key in [keyboard.Key.alt, keyboard.Key.alt_l, keyboard.Key.alt_r]:
            self.current_modifiers.add('alt')
        elif key == keyboard.Key.cmd:
            self.current_modifiers.add('cmd')

        # Create KeyEvent
        event = self._create_event(key)

        # Call callback
        try:
            self.callback(event)
        except Exception as e:
            print(f"Error in keyboard callback: {e}")

    def _on_release(self, key):
        """Handle key release event."""
        # Remove modifiers on release
        if key in [keyboard.Key.ctrl, keyboard.Key.ctrl_l, keyboard.Key.ctrl_r]:
            self.current_modifiers.discard('ctrl')
        elif key in [keyboard.Key.shift, keyboard.Key.shift_l, keyboard.Key.shift_r]:
            self.current_modifiers.discard('shift')
        elif key in [keyboard.Key.alt, keyboard.Key.alt_l, keyboard.Key.alt_r]:
            self.current_modifiers.discard('alt')
        elif key == keyboard.Key.cmd:
            self.current_modifiers.discard('cmd')

    def _create_event(self, key) -> KeyEvent:
        """
        Create a KeyEvent from a pynput key.

        Args:
            key: pynput key object

        Returns:
            KeyEvent instance
        """
        char = None
        key_name = ""

        # Determine character and key name
        if isinstance(key, keyboard.KeyCode):
            # Regular character key
            char = key.char
            key_name = char if char else f"char_{key.vk}"
        elif isinstance(key, keyboard.Key):
            # Special key
            key_name = self._get_special_key_name(key)
        else:
            key_name = str(key)

        return KeyEvent(
            key=key,
            char=char,
            modifiers=self.current_modifiers.copy(),
            key_name=key_name
        )

    def _get_special_key_name(self, key: keyboard.Key) -> str:
        """Get a human-readable name for special keys."""
        special_keys = {
            keyboard.Key.esc: "Esc",
            keyboard.Key.enter: "Enter",
            keyboard.Key.tab: "Tab",
            keyboard.Key.space: "Space",
            keyboard.Key.backspace: "Backspace",
            keyboard.Key.delete: "Delete",
            keyboard.Key.up: "Up",
            keyboard.Key.down: "Down",
            keyboard.Key.left: "Left",
            keyboard.Key.right: "Right",
            keyboard.Key.home: "Home",
            keyboard.Key.end: "End",
            keyboard.Key.page_up: "PageUp",
            keyboard.Key.page_down: "PageDown",
            keyboard.Key.insert: "Insert",
            keyboard.Key.f1: "F1",
            keyboard.Key.f2: "F2",
            keyboard.Key.f3: "F3",
            keyboard.Key.f4: "F4",
            keyboard.Key.f5: "F5",
            keyboard.Key.f6: "F6",
            keyboard.Key.f7: "F7",
            keyboard.Key.f8: "F8",
            keyboard.Key.f9: "F9",
            keyboard.Key.f10: "F10",
            keyboard.Key.f11: "F11",
            keyboard.Key.f12: "F12",
            keyboard.Key.ctrl: "Ctrl",
            keyboard.Key.ctrl_l: "Ctrl",
            keyboard.Key.ctrl_r: "Ctrl",
            keyboard.Key.shift: "Shift",
            keyboard.Key.shift_l: "Shift",
            keyboard.Key.shift_r: "Shift",
            keyboard.Key.alt: "Alt",
            keyboard.Key.alt_l: "Alt",
            keyboard.Key.alt_r: "Alt",
            keyboard.Key.cmd: "Cmd",
        }

        return special_keys.get(key, str(key).split('.')[-1])

    def __enter__(self):
        """Context manager entry."""
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.stop()
