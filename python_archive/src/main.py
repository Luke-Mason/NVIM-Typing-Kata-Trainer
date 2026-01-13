"""Main entry point for NVIM Typing Kata Trainer."""
import sys
from pathlib import Path

from .core.config import Config
from .app import VimTrainerApp


def print_banner():
    """Print application banner."""
    banner = """
===============================================================

         NVIM TYPING KATA TRAINER
         Master Vim Through Gamified Training

         100 Military Ranks
         6 Game Modes
         AI-Powered Feedback
         Progress Tracking

===============================================================
    """
    print(banner)


def main():
    """Main entry point."""
    # Set UTF-8 encoding for Windows console
    import sys
    if sys.platform == 'win32':
        try:
            import codecs
            sys.stdout.reconfigure(encoding='utf-8')
        except:
            # Fallback for older Python versions or if reconfigure fails
            pass

    print_banner()

    try:
        # Load configuration
        print("Loading configuration...")
        config = Config.from_env()

        # Validate configuration
        warnings = config.validate()
        if warnings:
            print("\n[WARNING]️  Configuration Warnings:")
            for warning in warnings:
                print(f"  • {warning}")
            print()

        if not config.claude_api_key:
            print("[ERROR] ERROR: CLAUDE_API_KEY not set!")
            print("\nPlease create a .env file with your Claude API key:")
            print("  1. Copy .env.example to .env")
            print("  2. Add your API key from https://console.anthropic.com/")
            print("  3. Run the application again\n")
            sys.exit(1)

        print(f"[OK] Configuration loaded successfully")
        print(f"[OK] API Key: Set")

        if config.vimrc_path:
            print(f"[OK] Vimrc: {config.vimrc_path}")
        else:
            print("[WARNING] Vimrc: Not found (AI feedback will be limited)")

        print(f"[OK] Progress Directory: {config.progress_dir}")
        print(f"[OK] Exit Sequence: {config.universal_exit_sequence}")
        print(f"[OK] AI Feedback: {config.ai_feedback_timing}")
        print()

        # Create and run application
        app = VimTrainerApp(config)
        app.run()

    except KeyboardInterrupt:
        print("\n\nInterrupted by user. Exiting...")
        sys.exit(0)
    except Exception as e:
        print(f"\n[ERROR] ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
