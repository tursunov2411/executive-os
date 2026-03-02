import asyncio
import keyboard
import logging
from config import SETTINGS
from enforcement import EnforcementEngine

# Set up simple logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

engine = EnforcementEngine()

def emergency_override():
    """Global emergency override triggered by hotkey"""
    print("\n" + "!"*50)
    print("!!! EMERGENCY OVERRIDE TRIGGERED !!!")
    print("!!! RESTORING ENVIRONMENT...     !!!")
    print("!"*50 + "\n")
    
    # Run sync since keyboard hooks don't run in the async loop natively easily
    try:
        loop = asyncio.get_event_loop()
        loop.create_task(engine.adapter.restore_environment())
    except RuntimeError:
        # Fallback if no loop
        asyncio.run(engine.adapter.restore_environment())

async def daemon_loop():
    print(f"[Daemon] Starting Windows Behavioral Governor")
    print(f"[Daemon] Mode: {'SAFE MODE (Sandbox Only)' if SETTINGS['SAFE_MODE'] else 'ACTIVE ENFORCEMENT (OS Level)'}")
    print(f"[Daemon] Bindings: CTRL+ALT+ESC for Emergency Break\n")
    
    # Register global emergency hotkey
    keyboard.add_hotkey('ctrl+alt+esc', emergency_override)
    
    while True:
        try:
            # 1. Fetch latest enforcement packet from FastAPI backend
            await engine.fetch_enforcement_packet()
            
            # 2. Apply enforcement rules (focus, block, processes)
            await engine.apply_rules()
            
            # 3. Wait a short interval before next cycle
            await asyncio.sleep(SETTINGS["ENFORCEMENT_INTERVAL"])
            
        except Exception as e:
            logging.error(f"[Daemon] Error: {e}")
            await asyncio.sleep(SETTINGS["ENFORCEMENT_INTERVAL"])

if __name__ == "__main__":
    try:
        asyncio.run(daemon_loop())
    except KeyboardInterrupt:
        print("\n[Daemon] Shutting down gracefully...")
        asyncio.run(engine.adapter.restore_environment())
