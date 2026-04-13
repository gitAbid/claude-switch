# Claude Code Profile Switcher Design

## Overview
A SwiftBar / xbar plugin written in Python 3 that allows the user to quickly switch between different Claude Code LLM backend profiles (e.g., Anthropic, Gemini, Z.ai/GLM) from the macOS menu bar. To preserve Claude Code plugin settings and permissions, profiles are applied using a selective "deep merge" rather than a full file overwrite.

## Architecture & Storage
1.  **Plugin Script:** `claude-profiles.10s.py` located in the user's SwiftBar plugins folder.
2.  **Profiles Directory:** `~/.claude/profiles/` containing partial JSON configurations.
3.  **State Tracking:** `~/.claude/.current_profile` storing the name of the active profile to display in the menu bar.

## Switcher Logic (`claude-profiles.10s.py`)
### Default Run (UI Generation)
1. Reads `~/.claude/.current_profile`.
2. Prints SwiftBar UI header: `🤖 Claude: <ProfileName>`.
3. Scans `~/.claude/profiles/*.json`.
4. Prints a dropdown menu item for each profile.
5. Menu item click action re-executes the script passing `--switch <basename>`.

### Switch Run (`--switch <basename>`)
1. **Scrub:** Loads `~/.claude/settings.json` and deletes managed keys to prevent bleed-over between profiles.
    *   *Root Managed Keys:* `model`
    *   *Env Managed Keys:* `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`
2. **Merge:** Loads `~/.claude/profiles/<basename>.json` and performs a dictionary update on `settings.json`.
3. **Save:** Writes the updated `settings.json` and updates `~/.claude/.current_profile` to `<basename>`.

## Initial Profile Configurations

### 1. `gemini.json`
```json
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
```

### 2. `zai.json`
```json
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
```

### 3. `anthropic.json`
```json
{
  "model": "claude-sonnet-4-6",
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.anthropic.com",
    "ANTHROPIC_API_KEY": "YOUR_ANTHROPIC_API_KEY"
  }
}
```
