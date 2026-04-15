# ClaudeSwitch

A native macOS menu bar app for switching between [Claude Code](https://docs.anthropic.com/en/docs/claude-code) profiles. Built with SwiftUI.

![macOS 13.0+](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## What it does

ClaudeSwitch lives in your menu bar and lets you quickly swap between different Claude Code configurations — each with its own API key, base URL, and model overrides. No more manually editing `~/.claude/settings.json`.

- **One-click profile switching** from the menu bar
- **Manage profiles** with a built-in UI — add, edit, delete
- **Automatic backup** — your `settings.json` is backed up before every switch
- **Supports** API keys, auth tokens, custom base URLs, and model overrides (sonnet, opus, haiku)

## How it works

Profiles are stored as JSON files in `~/.claude/profiles/`. Each profile maps to environment variables that Claude Code reads from `~/.claude/settings.json`:

| Profile field | Environment variable |
|---|---|
| API Key / Auth Token | `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN` |
| Base URL | `ANTHROPIC_BASE_URL` |
| Sonnet Model | `ANTHROPIC_DEFAULT_SONNET_MODEL` |
| Opus Model | `ANTHROPIC_DEFAULT_OPUS_MODEL` |
| Haiku Model | `ANTHROPIC_DEFAULT_HAIKU_MODEL` |

When you switch profiles, ClaudeSwitch:
1. Backs up your current `settings.json` to `settings.json.bak`
2. Scrubs any previously managed env keys
3. Merges the new profile's values into `settings.json`
4. Updates the active profile indicator

## Building

```bash
swift build -c release
```

The binary will be at `.build/release/ClaudeSwitch`.

## Running

```bash
# From the built binary
.build/release/ClaudeSwitch

# Or run directly during development
swift run
```

The app appears as an icon in your menu bar. Click it to switch profiles or open the management window.

## Project structure

```
├── Package.swift
└── Sources/
    ├── App.swift                    # Menu bar app entry point
    ├── Resources/
    │   └── AppIcon.icns             # App icon
    ├── Models/
    │   └── Profile.swift            # Profile model & serialization
    ├── Services/
    │   ├── ProfileStore.swift       # Profile loading & state management
    │   └── SettingsManager.swift    # Settings.json read/write & switching
    └── Views/
        ├── ManageView.swift         # Profile management window
        └── ProfileFormView.swift    # Add/edit profile form
```

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools (`xcode-select --install`)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
