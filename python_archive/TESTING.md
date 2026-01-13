# Testing Guide

This project uses Test-Driven Development (TDD) with pytest to ensure code quality and maintainability.

## Test Coverage Summary

Current test coverage: **89 tests, 100% pass rate**

### Fully Tested Components (100% coverage):
- ✅ **Exit Sequence Detector** (`src/core/constants.py`) - 17 tests
- ✅ **Stats Calculator** (`src/utils/stats_calculator.py`) - 31 tests

### Well-Tested Components (90%+ coverage):
- ✅ **Rank System** (`src/core/ranks.py`) - 18 tests, 90% coverage
- ✅ **Player Model** (`src/models/player.py`) - 20 tests, 94% coverage
- ✅ **Mode Stats** (`src/models/player.py`) - 7 tests

### Components Pending Tests:
- ⏳ Config system
- ⏳ Game modes
- ⏳ Input handlers
- ⏳ UI components
- ⏳ AI integration

## Running Tests

### Run All Tests
```bash
pytest
```

### Run Specific Test File
```bash
pytest tests/test_ranks.py
```

### Run Specific Test Class
```bash
pytest tests/test_ranks.py::TestRankSystem
```

### Run Specific Test
```bash
pytest tests/test_ranks.py::TestRankSystem::test_rank_system_loads_ranks
```

### Run with Verbose Output
```bash
pytest -v
```

### Run with Coverage Report
```bash
pytest --cov=src --cov-report=term-missing
```

### Run with HTML Coverage Report
```bash
pytest --cov=src --cov-report=html
# Open htmlcov/index.html in your browser
```

### Run Only Fast Tests (exclude slow tests)
```bash
pytest -m "not slow"
```

## Test Organization

Tests are organized by module:

```
tests/
├── test_constants.py      # Exit sequence detector tests
├── test_ranks.py          # Rank system tests
├── test_player.py         # Player and ModeStats tests
└── test_stats_calculator.py  # Utility function tests
```

## Test Categories

Tests are marked with pytest markers:

- `@pytest.mark.unit` - Unit tests (fast, isolated)
- `@pytest.mark.integration` - Integration tests (multiple components)
- `@pytest.mark.slow` - Slow tests (may take several seconds)
- `@pytest.mark.ui` - UI tests (require user interaction)

### Running Specific Categories
```bash
# Run only unit tests
pytest -m unit

# Run only integration tests
pytest -m integration

# Skip slow tests
pytest -m "not slow"
```

## Writing Tests

### Test Structure
We follow the Arrange-Act-Assert (AAA) pattern:

```python
def test_example():
    # Arrange: Set up test data
    player = Player(name="TestPlayer")

    # Act: Perform the action
    player.add_xp(100)

    # Assert: Verify the result
    assert player.current_xp == 100
```

### Test Naming Convention
- Test files: `test_<module>.py`
- Test classes: `Test<ClassName>`
- Test methods: `test_<what_it_tests>`

Examples:
- `test_rank_system_loads_ranks()` - Tests that rank system loads ranks
- `test_player_with_initial_values()` - Tests player creation with values
- `test_calculate_wpm_standard()` - Tests standard WPM calculation

### Using Fixtures
Pytest fixtures provide reusable test data:

```python
@pytest.fixture
def rank_system():
    """Create a rank system instance."""
    return RankSystem()

def test_get_rank(rank_system):
    # rank_system is injected by pytest
    rank = rank_system.get_rank(0)
    assert rank is not None
```

### Testing Exceptions
Use `pytest.raises()` to test expected exceptions:

```python
def test_invalid_rank():
    with pytest.raises(ValueError):
        rank = Rank(id=-1, name="Invalid", symbol="X", xp_required=-100)
```

## TDD Workflow

Follow the Red-Green-Refactor cycle:

### 1. 🔴 Red: Write a Failing Test
```python
def test_player_can_rank_up():
    player = Player(name="Test")
    player.add_xp(1000)
    # This will fail because we haven't implemented rank-up logic yet
    assert player.current_rank > 0
```

### 2. 🟢 Green: Make the Test Pass
Implement the minimum code to make the test pass:

```python
def add_xp(self, amount: int):
    self.current_xp += amount
    # Add rank-up logic
    if self.current_xp >= 100:
        self.current_rank += 1
```

### 3. 🔵 Refactor: Improve the Code
Clean up the implementation while keeping tests green:

```python
def add_xp(self, amount: int):
    self.current_xp += amount
    self._check_rank_up()  # Extract to separate method

def _check_rank_up(self):
    # More sophisticated rank-up logic
    rank = self.rank_system.get_rank_by_xp(self.current_xp)
    self.current_rank = rank.id
```

## Benefits of TDD

✅ **Confidence**: Know your code works before deploying
✅ **Documentation**: Tests document how code should behave
✅ **Design**: Forces you to think about interfaces first
✅ **Refactoring**: Safe to change code with test coverage
✅ **Regression Prevention**: Catch bugs early
✅ **Debugging**: Tests help isolate issues

## Test Examples

### Example 1: Testing Pure Functions
```python
def test_calculate_wpm_standard():
    """Test standard WPM calculation."""
    # 250 characters in 60 seconds = 50 WPM
    wpm = calculate_wpm(250, 60)
    assert wpm == 50.0
```

### Example 2: Testing Object State
```python
def test_player_increments_sessions():
    """Test that session count increments correctly."""
    player = Player(name="TestPlayer")
    assert player.total_sessions == 0

    player.increment_sessions()
    assert player.total_sessions == 1
```

### Example 3: Testing Time-Dependent Logic
```python
def test_sequence_with_timeout():
    """Test that sequence times out."""
    detector = ExitSequenceDetector("jk", timeout=0.1)

    detector.check("j")
    time.sleep(0.15)  # Wait longer than timeout
    result = detector.check("k")

    assert not result  # Should not detect
```

### Example 4: Testing Data Serialization
```python
def test_player_to_json_and_back():
    """Test player JSON serialization round-trip."""
    original = Player(name="TestPlayer", current_xp=1000)

    # Serialize
    json_str = original.to_json()

    # Deserialize
    loaded = Player.from_json(json_str)

    # Verify
    assert loaded.name == original.name
    assert loaded.current_xp == original.current_xp
```

## Continuous Integration

Tests run automatically on:
- Every commit (via pre-commit hooks)
- Every pull request (via GitHub Actions)
- Before deployment

## Test Metrics

Track these metrics over time:
- **Test Count**: Number of tests (currently 89)
- **Pass Rate**: Percentage passing (currently 100%)
- **Coverage**: Code coverage percentage (currently 18% overall, 100% for tested modules)
- **Speed**: Time to run all tests (currently 2.30s)

## Common Testing Patterns

### Pattern 1: Testing Boundaries
```python
def test_rank_boundaries():
    """Test behavior at rank boundaries."""
    rank_system = RankSystem()

    # Test minimum
    assert rank_system.get_rank(0) is not None

    # Test maximum
    assert rank_system.get_rank(99) is not None

    # Test out of bounds
    assert rank_system.get_rank(-1) is None
    assert rank_system.get_rank(100) is None
```

### Pattern 2: Testing Edge Cases
```python
def test_accuracy_with_zero_total():
    """Test accuracy calculation with zero inputs."""
    accuracy = calculate_accuracy(0, 0)
    assert accuracy == 100.0  # Should default to perfect
```

### Pattern 3: Testing Progression
```python
def test_rank_progression():
    """Test that ranks progress correctly."""
    rank_system = RankSystem()

    rank1 = rank_system.get_rank_by_xp(0)
    rank2 = rank_system.get_rank_by_xp(10000)
    rank3 = rank_system.get_rank_by_xp(500000)

    # Ranks should increase with XP
    assert rank1.id < rank2.id < rank3.id
```

## Debugging Failed Tests

### View Full Stack Trace
```bash
pytest --tb=long
```

### Run Only Failed Tests
```bash
pytest --lf
```

### Stop on First Failure
```bash
pytest -x
```

### Enter Debugger on Failure
```bash
pytest --pdb
```

### Show Print Statements
```bash
pytest -s
```

## Three Levels of Testing

This project now has **three types of tests** to catch bugs at different levels:

### 1. 🔬 Unit Tests (Fast & Isolated)
**Location**: `tests/test_*.py` (existing tests)
**Speed**: ⚡ Very Fast (~2 seconds)
**Purpose**: Test individual components in isolation

These test individual functions and classes without external dependencies:
- Rank system calculations
- Player state management
- Stats calculations
- Exit sequence detection

```bash
# Run unit tests only (exclude integration/system tests)
pytest tests/ -v --ignore=tests/test_gameplay_integration.py --ignore=tests/test_system_e2e.py
```

**Current Coverage**: 89 unit tests, 100% pass rate

### 2. 🎮 Integration Tests (Gameplay Simulation)
**Location**: `tests/test_gameplay_integration.py`
**Speed**: ⚡ Fast (~5-10 seconds)
**Purpose**: Simulate actual gameplay without running the full app

These tests directly call game mode classes and simulate user input:
- Test each game mode's update logic
- Test modifier key handling (Shift, Ctrl, Alt)
- Test uppercase letters and special characters
- Test invalid inputs are handled gracefully
- Test display text generation
- Test complete gameplay sequences

```bash
# Run integration tests
pytest tests/test_gameplay_integration.py -v

# Run specific integration test
pytest tests/test_gameplay_integration.py::TestWordTrainingGameplay::test_uppercase_word_motions -v
```

**Example Test**:
```python
async def test_uppercase_word_motions(self):
    """Test uppercase word motions (with Shift) don't crash."""
    mode = WordTrainingMode(config, player)
    await mode.generate_task()

    # Send Shift key (should be ignored)
    shift_event = create_key_event(key_name='Shift')
    await mode.update(shift_event)

    # Send uppercase letter
    event = create_key_event(char='W')
    result = await mode.update(event)
    assert isinstance(result, bool)  # Should not crash!
```

### 3. 🖥️ System Tests (End-to-End)
**Location**: `tests/test_system_e2e.py`
**Speed**: 🐢 Slower (~30-60 seconds)
**Purpose**: Test the ENTIRE application from startup to gameplay

These tests actually **run the full app** using Textual's test framework:
- Launch the application
- Navigate through menus
- Play each game mode
- Test keyboard shortcuts
- Test mode switching
- Test complete user sessions
- Stress test with rapid input

```bash
# Run system/e2e tests
pytest tests/test_system_e2e.py -v

# Run quick smoke test (just startup)
pytest tests/test_system_e2e.py::TestApplicationStartup -v
```

**Example Test**:
```python
async def test_uppercase_w_with_shift(self):
    """Test typing uppercase W (the bug we fixed)."""
    app = TypingTrainerApp()

    async with app.run_test() as pilot:
        # Launch Word Training
        await pilot.press("5")

        # Try typing W (this was causing crashes before)
        await pilot.press("W")

        # Should not crash!
        assert app.screen is not None
```

## Easy Test Runner

Use the `run_tests.py` script for convenient test execution:

```bash
# Run all tests
python run_tests.py all

# Run only unit tests (fast)
python run_tests.py unit

# Run only integration tests
python run_tests.py integration

# Run only system/e2e tests
python run_tests.py system

# Quick smoke test (just verify app starts)
python run_tests.py quick
```

## Why Multiple Test Levels?

Each level catches different types of bugs:

| Test Level | What It Catches | Example Bug |
|------------|----------------|-------------|
| **Unit** | Logic errors, calculation bugs | "XP calculation is wrong" |
| **Integration** | Component interaction bugs | "Modifier keys crash game mode" |
| **System** | Real-world usage bugs | "Menu navigation doesn't work" |

**The bug you found** (Shift+W crashing) would have been caught by:
- ❌ Unit tests (too isolated)
- ✅ Integration tests (test game modes directly)
- ✅ System tests (test full app)

## Test-First Development Workflow

When adding new features or fixing bugs:

### 1. Write a System Test First
```python
async def test_new_feature_works(self):
    """Test that new feature doesn't crash."""
    app = TypingTrainerApp()
    async with app.run_test() as pilot:
        await pilot.press("new_feature_key")
        assert app.screen is not None
```

### 2. Run It (It Should Fail Red)
```bash
pytest tests/test_system_e2e.py::test_new_feature_works -v
# Expected: FAILED
```

### 3. Implement the Feature
Write the actual code...

### 4. Run It Again (It Should Pass - Green)
```bash
pytest tests/test_system_e2e.py::test_new_feature_works -v
# Expected: PASSED ✓
```

### 5. Add Integration Tests for Edge Cases
```python
async def test_new_feature_with_shift(self):
    """Test new feature with Shift modifier."""
    # ... detailed testing
```

## Test Coverage Goals

| Component | Unit Tests | Integration Tests | System Tests |
|-----------|-----------|------------------|--------------|
| Game Modes | ✅ | ✅ | ✅ |
| Input Handling | ✅ | ✅ | ✅ |
| Menu Navigation | ⏳ | ⏳ | ✅ |
| AI Integration | ⏳ | ⏳ | ⏳ |
| Settings | ⏳ | ⏳ | ✅ |

## Common Test Scenarios

### Testing Modifier Keys
```python
# Integration test
async def test_shift_key_ignored(self):
    mode = WordTrainingMode(config, player)
    shift_event = create_key_event(key_name='Shift')
    result = await mode.update(shift_event)
    assert result is False  # Modifier ignored

# System test
async def test_uppercase_letters_work(self):
    async with app.run_test() as pilot:
        await pilot.press("W")  # Shift+W
        assert app.screen is not None
```

### Testing Complete Sessions
```python
async def test_full_training_session(self):
    """Simulate 5 minutes of training."""
    async with app.run_test() as pilot:
        await pilot.press("5")  # Start mode

        # Practice for a while
        for _ in range(100):
            await pilot.press("w")
            await pilot.press("b")

        # Exit and check stats
        await pilot.press("j")
        await pilot.press("k")
        await pilot.press("s")

        assert app.screen is not None
```

### Stress Testing
```python
async def test_rapid_input(self):
    """Test that rapid input doesn't crash."""
    async with app.run_test() as pilot:
        await pilot.press("5")

        # Rapid fire!
        for _ in range(50):
            await pilot.press("w")
            # No pause - as fast as possible

        assert app.screen is not None
```

## Benefits of This Testing Strategy

✅ **Catch bugs early** - Before users find them
✅ **Regression prevention** - Old bugs don't come back
✅ **Fearless refactoring** - Change code with confidence
✅ **Living documentation** - Tests show how features work
✅ **Better design** - Tests force good architecture
✅ **Faster debugging** - Failed tests pinpoint issues

## Real-World Example

**Bug**: Pressing Shift+W in Word Training mode crashed the app

**How we caught it**:
```python
# Integration test that would have caught this:
async def test_uppercase_word_motions(self):
    mode = WordTrainingMode(config, player)
    await mode.generate_task()

    # This would have failed before the fix
    event = create_key_event(char='W')
    result = await mode.update(event)  # ❌ CRASH!
    assert isinstance(result, bool)    # ✅ Now passes
```

**The fix**: Check for modifier keys and use `key_name` instead of `name`

**Lesson**: Integration and system tests catch the bugs that unit tests miss!

## Next Steps

To improve test coverage:

1. ✅ **Game Modes** - Integration tests added!
2. ✅ **Input Handlers** - System tests added!
3. ✅ **UI Components** - System tests added!
4. ⏳ **Config System** - Add unit tests for validation
5. ⏳ **Progress Manager** - Add save/load tests
6. ⏳ **AI Integration** - Add mocked API tests

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Textual Testing Guide](https://textual.textualize.io/guide/testing/)
- [TDD with Python](https://www.obeythetestinggoat.com/)
- [Test Coverage Best Practices](https://testing.googleblog.com/)

---

**Remember**:
- 🔬 Unit tests catch logic bugs
- 🎮 Integration tests catch interaction bugs
- 🖥️ System tests catch real-world bugs

**Write tests that simulate what users actually do - that's how you catch bugs before they reach production!**

---

**Tests are not just about finding bugs - they're about building confidence in your code and enabling fearless refactoring!**
