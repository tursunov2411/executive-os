import asyncio
from typing import Dict, Any
from windows_adapter import WindowsAdapter

class EnforcementEngine:
    
    def __init__(self):
        self.adapter = WindowsAdapter()
        self.current_packet = None
        
        # State tracking for graceful warnings
        self.warned_processes = {}
    
    async def fetch_enforcement_packet(self):
        """
        Polls the Executive OS Orchestrator API for the current ruleset.
        """
        import requests
        from config import SETTINGS
        
        try:
            # Poll the FastAPI layer for what we should be doing right now
            response = requests.get(f"{SETTINGS['ORCHESTRATOR_URL']}/api/active-enforcement", timeout=3)
            
            if response.status_code == 200:
                self.current_packet = response.json()
            else:
                # If API is up but returns no rules, clear current packet
                self.current_packet = None
                
        except requests.exceptions.RequestException as e:
            # If backend is down, we don't crash, we just pause enforcement updates
            print(f"[Enforcement] Cannot reach Orchestrator at {SETTINGS['ORCHESTRATOR_URL']}. Running cached or null ruleset.")
        
    async def apply_rules(self):
        if not self.current_packet:
            return
            
        print(f"\n[Enforcement] Applying ruleset: {self.current_packet['mode']}")
        
        # 1. Environment State
        await self.adapter.enable_focus_mode()
        
        # 2. Network State
        await self.adapter.block_domains(self.current_packet.get("blocked_domains", []))
        
        # 3. Process State (Graceful kill loop)
        await self.process_sentinel(self.current_packet.get("blocked_apps", []))
        
    async def process_sentinel(self, blocked_apps: list[str]):
        """
        5-second polling loop that detects forbidden processes.
        Issues a graceful warning (simulated via log), then terminates on next cycle.
        """
        import psutil
        
        print(f"[Sentinel] Scanning for non-compliant processes...")
        
        # Get all running process names
        running_procs = []
        for p in psutil.process_iter(['name']):
            try:
                running_procs.append(p.info['name'])
            except: pass
            
        for app in blocked_apps:
            if app in running_procs:
                if app not in self.warned_processes:
                    # 1st Strike: Warning
                    print(f"[Sentinel] WARNING: {app} is forbidden during {self.current_packet['mode']}. Terminating in 5s.")
                    self.warned_processes[app] = True
                else:
                    # 2nd Strike: Termination
                    print(f"[Sentinel] COMPLIANCE ENFORCED. Terminating {app}.")
                    await self.adapter.kill_process(app)
                    # Reset warning state if successfully killed
                    self.warned_processes.pop(app, None)
            else:
                # App is not running, reset warnings
                self.warned_processes.pop(app, None)
