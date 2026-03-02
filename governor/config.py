SETTINGS = {
    "SAFE_MODE": True,  # If True, only writes to sandbox JSON files
    "ENFORCEMENT_INTERVAL": 5,  # seconds
    "BACKUP_HOSTS_PATH": "C:/Windows/System32/drivers/etc/hosts.bak",
    "HOSTS_PATH": "C:/Windows/System32/drivers/etc/hosts",
    "ALLOWED_PROCESSES": ["explorer.exe", "code.exe", "chrome.exe", "msedge.exe", "WindowsTerminal.exe"],
    
    # API sync settings
    "ORCHESTRATOR_URL": "http://localhost:8000"
}
