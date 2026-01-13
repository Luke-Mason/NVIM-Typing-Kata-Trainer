"""Markdown report generation utilities."""
from datetime import datetime
from typing import Dict, Optional
from pathlib import Path

from ..models.player import Player, ModeStats
from ..core.ranks import RankSystem
from .stats_calculator import create_progress_bar, format_time


def generate_progress_report(
    player: Player,
    rank_system: RankSystem,
    output_file: Optional[Path] = None
) -> str:
    """
    Generate a markdown progress report for a player.

    Args:
        player: Player instance
        rank_system: RankSystem instance
        output_file: Optional path to write the report to

    Returns:
        Markdown report as a string
    """
    # Get current rank info
    current_rank = rank_system.get_rank(player.current_rank)
    next_rank = rank_system.get_next_rank(player.current_rank)
    is_max = rank_system.is_max_rank(player.current_rank)

    # Build the report
    lines = []
    lines.append("# NVIM Typing Kata Progress Report")
    lines.append("")
    lines.append(f"**Player**: {player.name}")
    lines.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("")

    # Rank section
    lines.append("## Current Rank")
    lines.append("")
    if current_rank:
        lines.append(f"**{current_rank.symbol} {current_rank.name}** (Rank {player.current_rank + 1}/100)")
    lines.append("")

    # XP Progress
    if not is_max and next_rank:
        progress_pct = rank_system.progress_to_next_rank(player.current_xp, player.current_rank)
        xp_needed = rank_system.xp_to_next_rank(player.current_xp, player.current_rank)
        xp_bar = create_progress_bar(player.current_xp, next_rank.xp_required, width=30)

        lines.append(f"**XP Progress**: {player.current_xp:,} / {next_rank.xp_required:,}")
        lines.append(f"{xp_bar}")
        lines.append(f"**XP to Next Rank** ({next_rank.symbol} {next_rank.name}): {xp_needed:,}")
    else:
        lines.append(f"**XP**: {player.current_xp:,}")
        lines.append("**Status**: MAX RANK ACHIEVED!")
    lines.append("")

    # Overall stats
    lines.append("## Overall Statistics")
    lines.append("")
    lines.append(f"- **Total Sessions**: {player.total_sessions}")
    lines.append(f"- **Total Playtime**: {format_time(player.total_playtime)}")
    lines.append(f"- **Account Created**: {player.created_at[:10]}")
    lines.append(f"- **Last Played**: {player.last_played[:10]}")
    lines.append("")

    # Mode-specific stats
    if player.stats:
        lines.append("## Game Mode Statistics")
        lines.append("")

        mode_names = {
            'snake_apple': '🐍 Snake Apple Mode',
            'symbol_training': '🔣 Symbol Training',
            'coding_lessons': '💻 Coding Lessons',
            'word_training': '📝 Word Training',
            'vim_motions': '⚡ Vim Motions',
            'comprehensive_keys': '⌨️ Comprehensive Keys',
        }

        for mode_key, stats in player.stats.items():
            mode_name = mode_names.get(mode_key, mode_key.replace('_', ' ').title())
            lines.append(f"### {mode_name}")
            lines.append("")
            lines.append(f"- **Tasks Completed**: {stats.tasks_completed}")
            lines.append(f"- **Average Accuracy**: {stats.total_accuracy:.1f}%")

            # Mode-specific speed metric
            if mode_key == 'coding_lessons':
                lines.append(f"- **Average WPM**: {stats.average_speed:.1f}")
            elif mode_key in ['snake_apple', 'comprehensive_keys']:
                lines.append(f"- **Average Time**: {stats.average_speed:.2f}s")
            else:
                lines.append(f"- **Average Speed**: {stats.average_speed:.2f}")

            lines.append(f"- **Best Streak**: {stats.best_streak}")
            lines.append(f"- **Total Time Played**: {format_time(stats.total_time_played)}")
            lines.append(f"- **XP Earned**: {stats.total_xp_earned:,}")

            # Extra data if present
            if stats.extra_data:
                lines.append("")
                lines.append("**Additional Stats:**")
                for key, value in stats.extra_data.items():
                    formatted_key = key.replace('_', ' ').title()
                    lines.append(f"- {formatted_key}: {value}")

            lines.append("")

    # Rank progression history
    lines.append("## Rank Progression")
    lines.append("")
    lines.append(f"Current Progress: Rank {player.current_rank + 1} of 100")

    if player.current_rank > 0:
        lines.append("")
        lines.append("**Milestones Achieved:**")
        # Show some key ranks achieved
        milestones = [0, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90]
        for milestone in milestones:
            if milestone <= player.current_rank:
                rank = rank_system.get_rank(milestone)
                if rank:
                    lines.append(f"- {rank.symbol} {rank.name} (Rank {milestone + 1})")

    lines.append("")

    # Footer
    lines.append("---")
    lines.append("")
    lines.append("*Generated by NVIM Typing Kata Trainer*")
    lines.append("")

    # Join all lines
    report = '\n'.join(lines)

    # Write to file if specified
    if output_file:
        output_file.parent.mkdir(parents=True, exist_ok=True)
        output_file.write_text(report, encoding='utf-8')

    return report


def generate_session_summary(
    mode_name: str,
    tasks_completed: int,
    accuracy: float,
    xp_earned: int,
    duration_seconds: float
) -> str:
    """
    Generate a brief session summary.

    Args:
        mode_name: Name of the game mode
        tasks_completed: Number of tasks completed
        accuracy: Accuracy percentage
        xp_earned: XP earned this session
        duration_seconds: Session duration in seconds

    Returns:
        Formatted summary string
    """
    lines = []
    lines.append(f"## Session Complete: {mode_name}")
    lines.append("")
    lines.append(f"- Tasks Completed: {tasks_completed}")
    lines.append(f"- Accuracy: {accuracy:.1f}%")
    lines.append(f"- XP Earned: +{xp_earned:,}")
    lines.append(f"- Duration: {format_time(duration_seconds)}")

    return '\n'.join(lines)
