# Progression System Specification

Complete specification of XP, ranks, stats tracking, and persistence.

---

## Overview

The progression system provides long-term motivation through:
- **XP (Experience Points)**: Earned from completing tasks
- **Ranks**: 100 military-themed ranks from Recruit to Vim Legend
- **Stats**: Per-mode analytics (accuracy, WPM, streaks)
- **Persistence**: JSON-based save system

---

## XP (Experience Points) System

### Base XP Values (Per Task)

| Game Mode | Base XP | Notes |
|-----------|---------|-------|
| Custom Keybindings | 15 XP | Per keybinding |
| Snake Apple | 10 XP | Per apple |
| Symbol Training | 5 XP | Per symbol |
| Coding Lessons | 50 XP | Per code snippet |
| Word Typing | 50 XP | Per 20-word session |
| Vim Motions | 30 XP | Per task |
| Comprehensive Keys | 5 XP | Per key |

### XP Bonus Formula

```
total_xp = base_xp + accuracy_bonus + speed_bonus + streak_bonus
```

#### 1. Accuracy Bonus (0-10 XP)
```
accuracy_bonus = (accuracy_percent / 100) * 10
```

Examples:
- 100% accuracy = +10 XP
- 90% accuracy = +9 XP
- 80% accuracy = +8 XP

#### 2. Speed Bonus (0-5 XP)
```
speed_bonus = min(speed_factor * 5, 5)
```

Where `speed_factor` is mode-specific:
- **WPM modes**: `speed_factor = min(wpm / 80, 1.0)`
  - 80+ WPM = max bonus (+5 XP)
  - 40 WPM = half bonus (+2.5 XP)
- **Time-based**: `speed_factor = min(target_time / actual_time, 1.0)`
  - Faster than target = max bonus
- **Move-based** (Snake): `speed_factor = optimal_moves / actual_moves`
  - Perfect efficiency = max bonus

#### 3. Streak Bonus (0-15 XP, capped)
```
streak_bonus = min(current_streak * 0.5, 15)
```

Examples:
- Streak of 30+ = +15 XP (capped)
- Streak of 10 = +5 XP
- Streak of 5 = +2.5 XP

### XP Calculation Examples

**Example 1: Word Typing Session**
- Base: 50 XP
- Accuracy: 95% → +9.5 XP
- WPM: 60 → +3.75 XP (60/80 * 5)
- Streak: 15 → +7.5 XP
- **Total**: 70.75 XP → rounded to 71 XP

**Example 2: Snake Apple**
- Base: 10 XP
- Accuracy: 100% (reached apple) → +10 XP
- Efficiency: 8 optimal / 12 actual → +3.33 XP (0.67 * 5)
- Streak: 20 → +10 XP
- **Total**: 33.33 XP → rounded to 33 XP

**Example 3: Symbol Training**
- Base: 5 XP
- Accuracy: 100% → +5 XP (max for symbols: accuracy * 5)
- Speed: 0.3s reaction → +4 XP
- Streak: 40 → +15 XP (capped)
- **Total**: 29 XP

### Implementation Code Reference

```python
# From src/utils/stats_calculator.py
def calculate_xp_bonus(
    base_xp: int,
    accuracy: float,
    speed_factor: float = 1.0,
    streak_count: int = 0
) -> int:
    """Calculate total XP with bonuses."""
    # Accuracy bonus (0-10 XP)
    accuracy_bonus = (accuracy / 100) * 10

    # Speed bonus (0-5 XP)
    speed_bonus = min(speed_factor * 5, 5)

    # Streak bonus (0-15 XP, capped)
    streak_bonus = min(streak_count * 0.5, 15)

    total = base_xp + accuracy_bonus + speed_bonus + streak_bonus
    return int(round(total))
```

---

## Rank System (100 Ranks)

### Rank Structure

**Data Source**: `data/ranks/rank_definitions.json`

```json
{
  "id": 15,
  "name": "Corporal",
  "symbol": "⚔️",
  "xp_required": 2800
}
```

### Rank Tiers

#### Tier 1: Recruits (Ranks 0-9)
| Rank | Name | Symbol | XP Required |
|------|------|--------|-------------|
| 0 | Recruit | 🌱 | 0 |
| 1 | Trainee | 👤 | 100 |
| 2 | Apprentice | 🎓 | 250 |
| 3 | Cadet | 🎖️ | 450 |
| 4 | Junior | 🔰 | 700 |
| 5 | Novice | 📚 | 1,000 |
| 6 | Learner | 📖 | 1,350 |
| 7 | Student | 🎒 | 1,750 |
| 8 | Private | ⚔️ | 2,200 |
| 9 | Private First Class | 🛡️ | 2,700 |

#### Tier 2: Soldiers (Ranks 10-29)
Military ranks: Private First Class → Sergeant Major
XP Range: 3,250 → 19,450

#### Tier 3: Officers (Ranks 30-49)
Officer ranks: Lieutenant → Colonel
XP Range: 20,800 → 66,800

#### Tier 4: Senior Officers (Ranks 50-59)
Brigadier General → General of the Army
XP Range: 70,600 → 171,300

#### Tier 5: Vim Ranks (Ranks 60-79)
Vim-specific titles: Vim Apprentice → Vim Grandmaster
XP Range: 177,200 → 308,300

Examples:
| Rank | Name | Symbol | XP Required |
|------|------|--------|-------------|
| 60 | Vim Apprentice | 📘 | 177,200 |
| 65 | Vim Expert | 🎯 | 220,400 |
| 70 | Vim Master | 🏆 | 260,300 |
| 75 | Vim Sensei | 🥋 | 284,600 |
| 79 | Vim Grandmaster | 👑 | 308,300 |

#### Tier 6: Elite & Legendary (Ranks 80-99)
Ultimate ranks: Vim Sage → Ultimate Vim God
XP Range: 316,200 → 500,000

Examples:
| Rank | Name | Symbol | XP Required |
|------|------|--------|-------------|
| 80 | Vim Sage | 🧙 | 316,200 |
| 85 | Vim Titan | ⚡ | 356,800 |
| 90 | Vim Deity | 🌟 | 398,400 |
| 95 | Vim Immortal | 💫 | 449,200 |
| 99 | Ultimate Vim God | 🔱 | 500,000 |

### Rank Progression Formula

XP progression follows an accelerating curve:

```
xp_required(rank) = floor(100 * (1.08 ^ rank))
```

Early ranks: ~100 XP between ranks
Mid ranks: ~5,000 XP between ranks
Late ranks: ~10,000+ XP between ranks

### Rank Calculation

```python
def get_rank_by_xp(total_xp: int) -> Rank:
    """Return highest rank achieved by XP."""
    for rank in reversed(rank_list):
        if total_xp >= rank.xp_required:
            return rank
    return rank_list[0]  # Recruit

def progress_to_next_rank(current_xp: int, current_rank: int) -> float:
    """Return percentage progress to next rank (0-100)."""
    current = ranks[current_rank].xp_required
    next_rank = ranks[current_rank + 1].xp_required

    progress = (current_xp - current) / (next_rank - current)
    return min(100, max(0, progress * 100))
```

---

## Stats Tracking System

### Per-Mode Statistics

**Data Structure** (ModeStats):
```python
@dataclass
class ModeStats:
    tasks_completed: int = 0
    total_accuracy: float = 0.0      # Rolling average %
    average_speed: float = 0.0       # Mode-specific metric
    best_streak: int = 0
    total_time_played: int = 0       # Seconds
    total_xp_earned: int = 0
    extra_data: Dict[str, Any] = {}  # Flexible storage
```

### Mode-Specific Speed Metrics

| Mode | Speed Metric | Unit |
|------|--------------|------|
| Word Typing | WPM | Words per minute |
| Coding Lessons | WPM | Words per minute |
| Snake Apple | Efficiency | Optimal/actual moves |
| Symbol Training | Reaction Time | Seconds |
| Comprehensive Keys | Reaction Time | Seconds |
| Custom Keybindings | Time per key | Seconds |
| Vim Motions | Completion Time | Seconds |

### Extra Data Examples

**Word Typing**:
```json
"extra_data": {
  "best_wpm": 78.5,
  "total_words_typed": 1240,
  "total_characters": 6200
}
```

**Snake Apple**:
```json
"extra_data": {
  "best_moves": 8,
  "total_apples": 342,
  "average_moves": 12.4
}
```

**Coding Lessons**:
```json
"extra_data": {
  "languages": {
    "python": 45,
    "javascript": 23,
    "rust": 12
  },
  "total_lines": 567
}
```

### Session Tracking

**GameSession** (during active gameplay):
```python
@dataclass
class GameSession:
    mode_name: str
    start_time: datetime
    end_time: Optional[datetime] = None

    tasks_completed: int = 0
    current_streak: int = 0
    best_streak: int = 0

    total_keystrokes: int = 0
    correct_keystrokes: int = 0
    error_count: int = 0

    xp_earned: int = 0

    mode_data: Dict[str, Any] = {}  # Flexible per-mode storage
```

**Methods**:
- `record_keystroke(correct: bool)` - Track each key press
- `calculate_accuracy() -> float` - Current accuracy %
- `add_task_completion(xp: int)` - Record completed task
- `end()` - Mark session complete

### Stats Aggregation

On session end:
```python
# Update player's mode stats
mode_stats = player.get_mode_stats(mode_name)

mode_stats.tasks_completed += session.tasks_completed
mode_stats.total_xp_earned += session.xp_earned
mode_stats.total_time_played += session.duration_seconds
mode_stats.best_streak = max(mode_stats.best_streak, session.best_streak)

# Update rolling accuracy
total_keys = mode_stats.tasks_completed
new_accuracy = session.calculate_accuracy()
mode_stats.total_accuracy = (
    (mode_stats.total_accuracy * (total_keys - 1) + new_accuracy) / total_keys
)
```

---

## Persistence System

### File Structure

```
progress/
├── player_profile.json          # Main save file
├── player_profile_backup_*.json # Timestamped backups
└── progress_report.md           # Human-readable summary
```

### Player Profile JSON Schema

```json
{
  "name": "PlayerName",
  "current_xp": 15420,
  "current_rank": 42,
  "created_at": "2025-01-14T10:30:00",
  "last_played": "2025-01-14T18:45:00",
  "total_sessions": 127,
  "total_playtime": 18600,

  "stats": {
    "word_typing": {
      "tasks_completed": 45,
      "total_accuracy": 94.2,
      "average_speed": 62.5,
      "best_streak": 28,
      "total_time_played": 3600,
      "total_xp_earned": 3200,
      "extra_data": {
        "best_wpm": 78.5
      }
    },
    "snake_apple": {
      "tasks_completed": 120,
      "total_accuracy": 98.0,
      "average_speed": 0.85,
      "best_streak": 45,
      "total_time_played": 4200,
      "total_xp_earned": 4100,
      "extra_data": {
        "best_moves": 6,
        "total_apples": 120
      }
    }
    // ... other modes
  }
}
```

### Save/Load Operations

**On App Start**:
```python
progress_manager = ProgressManager(progress_dir)
player = progress_manager.load_player(default_name="Player")
```

**On Session End**:
```python
player.add_xp(session.xp_earned)
player.increment_sessions()
player.add_playtime(session.duration_seconds)

# Update mode stats
mode_stats = player.get_mode_stats(session.mode_name)
# ... update stats

progress_manager.save_player(player, update_markdown=True)
```

**Before Major Changes** (optional):
```python
progress_manager.backup_progress()  # Creates timestamped backup
```

### Progress Report (Markdown)

Auto-generated human-readable summary:

```markdown
# Typing Trainer Progress Report

**Player**: PlayerName
**Rank**: 🏆 Vim Master (Rank 70)
**Total XP**: 260,500 / 272,000 (96% to next rank)

## Overall Stats
- Total Sessions: 342
- Total Playtime: 45h 23m
- Favorite Mode: Word Typing (45% of time)

## Mode Statistics

### 📝 Word Typing
- Tasks Completed: 450
- Accuracy: 94.2%
- Average WPM: 62.5
- Best WPM: 78.5
- Best Streak: 28
- XP Earned: 32,500

### 🐍 Snake Apple
- Apples Collected: 1,240
- Accuracy: 98.0%
- Average Efficiency: 85%
- Best Moves: 6
- XP Earned: 41,200

[... other modes ...]
```

---

## Neovim Plugin Adaptations

### Storage Location Options

**Option 1: Neovim Data Directory**
```lua
local data_dir = vim.fn.stdpath('data') .. '/typing_trainer/'
-- Example: ~/.local/share/nvim/typing_trainer/
```

**Option 2: Config Directory**
```lua
local config_dir = vim.fn.stdpath('config') .. '/typing-trainer/'
-- Example: ~/.config/nvim/typing-trainer/
```

**Recommended**: Use `stdpath('data')` for saves, `stdpath('config')` for settings

### Lua Implementation

```lua
-- Load player profile
local function load_player()
  local profile_path = vim.fn.stdpath('data') .. '/typing_trainer/player_profile.json'
  local file = io.open(profile_path, 'r')
  if not file then
    return create_new_player()
  end

  local content = file:read('*a')
  file:close()

  local player = vim.json.decode(content)
  return player
end

-- Save player profile
local function save_player(player)
  local profile_path = vim.fn.stdpath('data') .. '/typing_trainer/player_profile.json'
  local file = io.open(profile_path, 'w')

  player.last_played = os.date('!%Y-%m-%dT%H:%M:%S')

  file:write(vim.json.encode(player))
  file:close()
end

-- Calculate rank
local function get_rank_by_xp(xp)
  for i = #ranks, 1, -1 do
    if xp >= ranks[i].xp_required then
      return ranks[i]
    end
  end
  return ranks[1]
end
```

### Rank Display in Statusline

```lua
-- Add to statusline
local function get_rank_statusline()
  local player = load_player()
  local rank = get_rank_by_xp(player.current_xp)
  return string.format("%s %s (XP: %d)", rank.symbol, rank.name, player.current_xp)
end

-- Use in statusline config
vim.opt.statusline = "%f %m %=%{v:lua.typing_trainer.get_rank_statusline()}"
```

### Auto-Save on Exit

```lua
-- Auto-save player progress when exiting Neovim
vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*",
  callback = function()
    if _G.typing_trainer_player then
      save_player(_G.typing_trainer_player)
    end
  end
})
```

---

## Summary

**Key Concepts**:
1. XP earned from tasks with accuracy/speed/streak bonuses
2. 100 ranks (0-99) with exponential XP requirements
3. Per-mode stats tracking (accuracy, speed, streaks)
4. JSON persistence with backups
5. Markdown reports for human readability

**For Neovim Plugin**:
- Use `vim.json` for encoding/decoding
- Store in `stdpath('data')`
- Auto-save on VimLeavePre
- Display rank in statusline
- Keep same XP formulas and rank structure

**Implementation Priority**:
1. Basic save/load (JSON)
2. XP calculation functions
3. Rank lookup by XP
4. Session tracking
5. Auto-save hooks
6. Progress display (:command)
7. Statusline integration
