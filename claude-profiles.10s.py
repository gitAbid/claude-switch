#!/usr/bin/env python3

import os
import sys
import json
from pathlib import Path
import subprocess

CLAUDE_DIR = Path.home() / ".claude"
PROFILES_DIR = CLAUDE_DIR / "profiles"
SETTINGS_FILE = CLAUDE_DIR / "settings.json"
CURRENT_PROFILE_FILE = CLAUDE_DIR / ".current_profile"

def get_current_profile():
    if CURRENT_PROFILE_FILE.exists():
        return CURRENT_PROFILE_FILE.read_text().strip()
    return "Unknown"

def render_ui():
    current = get_current_profile()
    print(f"🤖 Claude: {current.capitalize()}")
    print("---")
    
    if not PROFILES_DIR.exists():
        print("No profiles found")
        return
        
    for profile_file in sorted(PROFILES_DIR.glob("*.json")):
        profile_name = profile_file.stem
        # SwiftBar syntax to run a terminal command in the background
        script_path = os.path.abspath(__file__)
        is_checked = " (Active)" if profile_name == current else ""
        print(f"{profile_name.capitalize()}{is_checked} | bash='python3' param1='{script_path}' param2='--switch' param3='{profile_name}' terminal=false refresh=true")

if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--switch":
        # We will implement switch logic in Task 3
        print(f"Switching to {sys.argv[2]}...")
    else:
        render_ui()
