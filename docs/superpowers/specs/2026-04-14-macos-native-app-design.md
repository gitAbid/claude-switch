# Claude Profile Switcher — Native macOS Menu Bar App

## Overview

A standalone macOS menu bar utility for managing and switching Claude Code profiles. Lives entirely in the menu bar (no Dock icon). Built with SwiftUI using `MenuBarExtra` (macOS 13+). Replaces the existing SwiftBar plugin.

## Problem Statement

The current SwiftBar plugin works for profile switching but fights SwiftBar's limitations for any UI beyond simple menu items: submenus mangle arguments, background processes lose focus, no native form inputs. A standalone app eliminates all of these issues.

## Architecture

### Core Components

1. **ProfileStore** — Reads/writes `~/.claude/profiles/*.json`, watches directory for changes, tracks current profile via `~/.claude/.current_profile`
2. **SettingsManager** — Applies a profile to `~/.claude/settings.json` using the existing scrub-and-merge logic (ported to Swift)
3. **App** — SwiftUI `MenuBarExtra` with `.menu` style dropdown + a popover `Window` for management

### Data Format (backward compatible)

Profiles remain as JSON files in `~/.claude/profiles/`:

```json
{
  "model": "gemini-3.1-pro-high",
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8045",
    "ANTHROPIC_API_KEY": "sk-xxx",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gemini-3.1-pro-low",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "gemini-3.1-pro-high",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gemini-3-flash"
  }
}
```

Switching logic: scrub managed keys from `settings.json`, merge profile data in, write to disk.

## UI Design

### Design System

- **Style:** Native macOS utility — follow Apple HIG, use system controls (no custom theming)
- **Icons:** SF Symbols (native, consistent, always available on macOS)
- **Typography:** System font (SF Pro) via SwiftUI defaults
- **Colors:** System semantic colors (`.primary`, `.secondary`, `.tint`, `.red`) — automatic dark/light mode support
- **Layout:** 8pt spacing grid
- **Touch targets:** Minimum 28pt height for menu items (Apple HIG), 24pt for form fields

### Menu Bar Dropdown (always visible)

```
[SF Symbol: cpu] Zai                    ← Shows current profile name
─────────────────────────────────
 ● Anthropic                          ← Click to switch
   Gemini
   Minimax
   Zai  ✓                             ← Active profile has checkmark
─────────────────────────────────
 [SF Symbol: plus] Add Profile
 [SF Symbol: gearshape] Manage...     ← Opens management popover
─────────────────────────────────
 Quit
```

- **Menu style**: `MenuBarExtra("Claude", systemImage: "cpu") { ... }` with `.menuBarExtraStyle(.menu)`
- Profile names use SF Symbol `circle` for inactive, `checkmark.circle.fill` for active
- Dividers separate: header, profiles, actions, quit

### Manage Profiles Popover (SwiftUI Window)

A compact native window that opens from "Manage..." menu item. Fixed size ~600x400pt.

**Layout: Two-column with sidebar**

```
┌─────────────────────────────────────────────────┐
│  Claude Profile Switcher                [− □ ×] │
├──────────────┬──────────────────────────────────┤
│              │                                  │
│  > Anthropic │  Edit Profile                    │
│    Gemini    │                                  │
│    Minimax   │  Profile Name                    │
│    Zai  ●    │  ┌──────────────────────────┐    │
│              │  │ Gemini                    │    │
│              │  └──────────────────────────┘    │
│              │                                  │
│              │  Base URL                        │
│              │  ┌──────────────────────────┐    │
│              │  │ http://127.0.0.1:8045    │    │
│              │  └──────────────────────────┘    │
│              │                                  │
│              │  API Token                       │
│  [+ Add]     │  ┌•••••••••••••••••••••••••┐    │
│              │  └──────────────────────────┘    │
│              │                                  │
│              │  Model Mappings                  │
│              │  Sonnet  ┌───────────────────┐   │
│              │          │ gemini-3.1-pro-low │   │
│              │          └───────────────────┘   │
│              │  Opus    ┌───────────────────┐   │
│              │          │ gemini-3.1-pro-high│   │
│              │          └───────────────────┘   │
│              │  Haiku   ┌───────────────────┐   │
│              │          │ gemini-3-flash     │   │
│              │          └───────────────────┘   │
│              │                                  │
│              │  [Delete Profile]    [Save]      │
└──────────────┴──────────────────────────────────┘
```

**Sidebar:**
- `List` with `selection` binding
- Active profile shows a filled circle indicator (system color)
- Selected profile highlights with system selection color
- Footer has a "+" button to add new profile
- Right-click or swipe reveals "Delete" option

**Form (right panel):**
- Standard SwiftUI `Form` with `TextField` and `SecureField`
- Fields grouped: Identity (name), Connection (URL, token), Model Mappings (sonnet, opus, haiku)
- Labels above fields (not inline placeholders)
- "Save" button enabled only when changes are detected
- "Delete Profile" button in red, separated from Save, requires confirmation dialog
- Changes save immediately on button click (no separate "apply" step)

**Empty state (no profiles):**
- Center text: "No profiles yet" with a "Add Profile" button

**Add Profile flow:**
- Clicking "+" in sidebar creates a new untitled profile and selects it
- User fills in fields and clicks Save
- Profile is not persisted to disk until Save is clicked

### Window Behavior
- Opens as a standard SwiftUI `Window` (not a popover/sheet)
- No Dock icon — `ApplicationDelegate` sets `activationPolicy = .accessory`
- Window appears centered on screen when opened
- Closing the window hides it (app stays in menu bar)
- Reopening from "Manage..." menu brings window to front

## File Structure

```
ClaudeProfileSwitcher/
├── Package.swift
├── Sources/
│   └── ClaudeProfileSwitcher/
│       ├── App.swift              # @main, MenuBarExtra, WindowGroup
│       ├── Models/
│       │   └── Profile.swift      # Profile model, Codable
│       ├── Services/
│       │   ├── ProfileStore.swift  # Read/write profiles, FS watcher
│       │   └── SettingsManager.swift # Switch logic (scrub + merge)
│       └── Views/
│           ├── ProfileListView.swift   # Sidebar list
│           ├── ProfileFormView.swift   # Edit form
│           └── ManageWindow.swift      # Two-column layout
└── Resources/
    └── Assets.xcassets           # App icon (optional)
```

## Build & Install

```bash
# Build
cd ClaudeProfileSwitcher
swift build -c release

# Create app bundle (script provided)
./scripts/create-app-bundle.sh

# Install
cp -r ClaudeProfileSwitcher.app /Applications/

# Set to auto-launch (optional)
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/ClaudeProfileSwitcher.app", hidden:true}'
```

## Migration from SwiftBar Plugin

1. Build and install the app
2. Launch it — profiles are auto-discovered from `~/.claude/profiles/`
3. Remove `claude-profiles.10s.py` from `~/Documents/SwiftBar/plugins/`
4. Disable SwiftBar (optional) or keep it for other plugins

## Error Handling

- If `~/.claude/settings.json` is malformed: show alert, offer to restore from `.json.bak`
- If profile file is corrupted: show error in sidebar, allow deletion
- If no profiles exist: show empty state with "Add Profile" CTA

## Constraints

- macOS 13+ (Ventura) required for `MenuBarExtra`
- No third-party dependencies
- No network calls — purely local file operations
- Backward compatible with existing profile JSON format
