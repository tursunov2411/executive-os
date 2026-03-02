import os
import json
import ctypes
import time
from config import SETTINGS

class WindowsAdapter:
    
    def __init__(self):
        self.sandbox = SETTINGS["SAFE_MODE"]
        self.sandbox_dir = "sandbox"
        
        # Ensure sandbox files exist
        if self.sandbox:
            os.makedirs(self.sandbox_dir, exist_ok=True)
            for f in ["focus_state.json", "blocked_domains.json", "terminated_processes.json"]:
                path = os.path.join(self.sandbox_dir, f)
                if not os.path.exists(path):
                    with open(path, 'w') as fh: json.dump([], fh)
    
    async def enable_focus_mode(self):
        """Enables Do Not Disturb / Focus Assist"""
        if self.sandbox:
            with open(f"{self.sandbox_dir}/focus_state.json", "w") as f:
                json.dump({"enabled": True, "timestamp": time.time()}, f, indent=2)
            print("[Adapter] Focus mode simulated in sandbox")
        else:
            # Setting Windows Focus Assist via Registry/Powershell
            # requires elevated privileges
            os.system(r'powershell -Command "Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings -Name NOC_GLOBAL_SETTING_TOASTS_ENABLED -Value 0"')
            print("[Adapter] Windows Focus Assist Enabled (Toasts off)")
            
    async def disable_focus_mode(self):
        if self.sandbox:
            with open(f"{self.sandbox_dir}/focus_state.json", "w") as f:
                json.dump({"enabled": False, "timestamp": time.time()}, f, indent=2)
            print("[Adapter] Focus mode disabled in sandbox")
        else:
            os.system(r'powershell -Command "Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings -Name NOC_GLOBAL_SETTING_TOASTS_ENABLED -Value 1"')
            print("[Adapter] Windows Focus Assist Disabled")
    
    async def block_domains(self, domains: list[str]):
        """Modifies hosts file to redirect traffic to localhost"""
        if self.sandbox:
            with open(f"{self.sandbox_dir}/blocked_domains.json", "w") as f:
                json.dump(domains, f, indent=2)
            print(f"[Adapter] Domains blocked in sandbox: {domains}")
        else:
            # Backup hosts if not exists
            if not os.path.exists(SETTINGS["BACKUP_HOSTS_PATH"]):
                os.system(f'copy "{SETTINGS["HOSTS_PATH"]}" "{SETTINGS["BACKUP_HOSTS_PATH"]}"')
                
            with open(SETTINGS["HOSTS_PATH"], "a") as f:
                for domain in domains:
                    f.write(f"\n127.0.0.1 {domain} # ExecutiveOS")
            print(f"[Adapter] Domains blocked in real hosts file: {domains}")
    
    async def kill_process(self, process_name: str):
        """Terminates processes via taskkill"""
        if self.sandbox:
            # Append to sandbox log
            path = f"{self.sandbox_dir}/terminated_processes.json"
            try:
                with open(path, "r") as f: data = json.load(f)
            except:
                data = []
            data.append({"process": process_name, "timestamp": time.time()})
            with open(path, "w") as f: json.dump(data, f, indent=2)
                
            print(f"[Adapter] Would terminate {process_name} (sandbox)")
        else:
            os.system(f'taskkill /F /IM {process_name} /T >nul 2>&1')
            print(f"[Adapter] Process terminated: {process_name}")
    
    async def restore_environment(self):
        """Completely reverts all locks and unlocks Focus"""
        print("[Adapter] RESTORING ENVIRONMENT...")
        await self.disable_focus_mode()
        
        if self.sandbox:
            print("[Adapter] Sandbox restore triggered")
        else:
            # Restore hosts file
            if os.path.exists(SETTINGS["BACKUP_HOSTS_PATH"]):
                os.system(f'copy /Y "{SETTINGS["BACKUP_HOSTS_PATH"]}" "{SETTINGS["HOSTS_PATH"]}"')
            print("[Adapter] Environment restored (Hosts reverted)")
