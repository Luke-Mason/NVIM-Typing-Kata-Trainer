# Python TUI Implementation Archive

This directory contains the original Python TUI implementation that served as a prototype.

## Status: Archived

This Python version validated concepts and gathered user feedback. The project is now transitioning to a native Neovim plugin.

## Running the Python Version

```bash
pip install -r requirements.txt
python -m src.main
```

## What's Here

- `src/` - Python source code (8 game modes, UI, core systems)
- `tests/` - 180+ tests
- `data/` - Rank definitions JSON
- Various `.md` files - Implementation documentation

## Documentation

For complete project documentation, see: `../docs/`

## Key Lessons

- Vim simulation is inadequate (can't do 5w, d3w)
- Separate TUI interrupts workflow
- Game 5 needed complete redesign

These lessons inform the Neovim plugin design.

For details: `../docs/LESSONS_LEARNED.md`
