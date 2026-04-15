# Claude Code Profile Switcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a SwiftBar/xbar Python plugin that switches Claude Code profiles without destroying existing plugin/permission configs.

**Architecture:** A Python script that acts as both a SwiftBar UI generator and a background worker. It reads partial JSON configurations from `~/.claude/profiles` and deep merges them into `~/.claude/settings.json`, deliberately scrubbing specific managed keys first.

**Tech Stack:** Python 3 (native macOS), standard libraries (`json`, `pathlib`, `sys`, `os`, `subprocess`). No external dependencies.

---

### Task 1: Setup Directory Structure & Profiles

**Files:**
- Create: `~/.claude/profiles/gemini.json`
- Create: `~/.claude/profiles/zai.json`
- Create: `~/.claude/profiles/anthropic.json`
- Create: `~/.claude/.current_profile`

- [ ] **Step 1: Write profile creation bash script**

```bash
cat << 'EOF' > setup_profiles.sh
#!/bin/bash
mkdir -p ~/.claude/profiles

cat << 'JSON' > ~/.claude/profiles/gemini.json
{
  "model": "gemini-3.1-pro-high",
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8045",
    "ANTHROPIC_API_KEY": "sk-f7fef0e53e4f4ac18fabb0ddb3ad4713",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "gemini-3.1-pro-high",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gemini-3.1-pro-low",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gemini-3-flash"
  }
}
JSON

cat << 'JSON' > ~/.claude/profiles/zai.json
{
  "model": "glm-5-turbo",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "6a033b207fcb47ac92ac36d4ef45d18c.qZ9YRA1YgGvq7ygC",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5-turbo",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5.1",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.7-flash"
  }
}
JSON

cat << 'JSON' > ~/.claude/profiles/anthropic.json
{
  "model": "claude-sonnet-4-6",
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.anthropic.com",
    "ANTHROPIC_API_KEY": "YOUR_ANTHROPIC_API_KEY"
  }
}
JSON

echo "gemini" > ~/.claude/.current_profile

chmod +x setup_profiles.sh
./setup_profiles.sh
rm setup_profiles.sh
EOF
bash setup_profiles.sh
```

- [ ] **Step 2: Run setup script**

Run: `bash setup_profiles.sh`
Expected: Silent creation of files.

- [ ] **Step 3: Verify creation**

Run: `ls -la ~/.claude/profiles`
Expected: Shows the three `.json` files.

- [ ] **Step 4: Commit**

```bash
git commit --allow-empty -m "chore: setup initial claude profiles and directory structure"
```

---

### Task 2: Create Switcher Script Skeleton & UI Logic

**Files:**
- Create: `claude-profiles.10s.py`

- [ ] **Step 1: Write UI code**

```python
cat << 'EOF' > claude-profiles.10s.py
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
EOF
```

- [ ] **Step 2: Make executable**

Run: `chmod +x claude-profiles.10s.py`
Expected: No output.

- [ ] **Step 3: Test UI render**

Run: `./claude-profiles.10s.py`
Expected output:
```
🤖 Claude: Gemini
---
Anthropic | bash='python3' param1='/Users/abid/Projects/claude-code-profile-switcher/claude-profiles.10s.py' param2='--switch' param3='anthropic' terminal=false refresh=true
Gemini (Active) | bash='python3' param1='/Users/abid/Projects/claude-code-profile-switcher/claude-profiles.10s.py' param2='--switch' param3='gemini' terminal=false refresh=true
Zai | bash='python3' param1='/Users/abid/Projects/claude-code-profile-switcher/claude-profiles.10s.py' param2='--switch' param3='zai' terminal=false refresh=true
```

- [ ] **Step 4: Commit**

```bash
git add claude-profiles.10s.py
git commit -m "feat: add swiftbar python script ui generator"
```

---

### Task 3: Implement Switcher Deep Merge Logic

**Files:**
- Modify: `claude-profiles.10s.py`

- [ ] **Step 1: Write switch implementation**

Replace the `--switch` logic block in the script.

```python
cat << 'EOF' > patch.py
import sys

old_code = """if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--switch":
        # We will implement switch logic in Task 3
        print(f"Switching to {sys.argv[2]}...")
    else:
        render_ui()"""

new_code = """
MANAGED_ROOT_KEYS = ["model", "customModels", "systemPrompt"]
MANAGED_ENV_KEYS = [
    "ANTHROPIC_API_KEY", 
    "ANTHROPIC_AUTH_TOKEN", 
    "ANTHROPIC_BASE_URL", 
    "ANTHROPIC_DEFAULT_SONNET_MODEL", 
    "ANTHROPIC_DEFAULT_OPUS_MODEL", 
    "ANTHROPIC_DEFAULT_HAIKU_MODEL"
]

def switch_profile(profile_name):
    profile_path = PROFILES_DIR / f"{profile_name}.json"
    if not profile_path.exists():
        return
        
    try:
        if SETTINGS_FILE.exists():
            settings = json.loads(SETTINGS_FILE.read_text())
        else:
            settings = {}
            
        profile_data = json.loads(profile_path.read_text())
        
        # 1. Scrub managed root keys
        for key in MANAGED_ROOT_KEYS:
            if key in settings:
                del settings[key]
                
        # 2. Scrub managed env keys
        if "env" in settings:
            for key in MANAGED_ENV_KEYS:
                if key in settings["env"]:
                    del settings["env"][key]
        else:
            settings["env"] = {}
            
        # 3. Merge Profile Data
        for k, v in profile_data.items():
            if k == "env":
                if "env" not in settings:
                    settings["env"] = {}
                settings["env"].update(v)
            else:
                settings[k] = v
                
        # 4. Save
        # Make a backup just in case
        if SETTINGS_FILE.exists():
            backup_path = SETTINGS_FILE.with_suffix(".json.bak")
            backup_path.write_text(SETTINGS_FILE.read_text())
            
        SETTINGS_FILE.write_text(json.dumps(settings, indent=2))
        CURRENT_PROFILE_FILE.write_text(profile_name)
        
        # Reload swiftbar if available (macOS specific command)
        subprocess.run(["open", "swiftbar://refreshplugin?name=claude-profiles"], capture_output=True)
        
    except Exception as e:
        # In a background script, we can't easily print errors to user, but we can write to a log
        error_log = CLAUDE_DIR / "profile_switcher_error.log"
        error_log.write_text(str(e))

if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--switch":
        switch_profile(sys.argv[2])
    else:
        render_ui()"""

target = "claude-profiles.10s.py"
with open(target, 'r') as f:
    content = f.read()

content = content.replace(old_code, new_code)

with open(target, 'w') as f:
    f.write(content)
EOF
python3 patch.py
rm patch.py
```

- [ ] **Step 2: Run test switch**

Run: `./claude-profiles.10s.py --switch zai`
Expected: No output

- [ ] **Step 3: Verify switch results**

Run: `cat ~/.claude/settings.json | grep model -A 2 -B 2 && cat ~/.claude/.current_profile`
Expected: Shows settings for Z.ai `glm-5-turbo` and `zai` in current profile.

- [ ] **Step 4: Commit**

```bash
git add claude-profiles.10s.py
git commit -m "feat: implement profile switching with managed key scrubbing"
```
