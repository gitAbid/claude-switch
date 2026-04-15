# Claude Profile Switcher macOS App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar app that replaces the SwiftBar plugin for managing and switching Claude Code profiles.

**Architecture:** SwiftUI app using `MenuBarExtra(.menu)` for quick profile switching and a separate `Window` for profile management (add/edit/delete). Single Swift Package with no dependencies.

**Tech Stack:** Swift 6, SwiftUI, macOS 13+ (Ventura)

---

## File Structure

| File | Responsibility |
|------|---------------|
| `ClaudeProfileSwitcher/Package.swift` | SPM manifest, macOS 13 target |
| `ClaudeProfileSwitcher/Sources/App.swift` | `@main` app entry, `MenuBarExtra`, `Window` for management |
| `ClaudeProfileSwitcher/Sources/Models/Profile.swift` | Profile struct, Codable, flat-field representation |
| `ClaudeProfileSwitcher/Sources/Services/ProfileStore.swift` | CRUD on `~/.claude/profiles/*.json`, directory watcher, current profile tracking |
| `ClaudeProfileSwitcher/Sources/Services/SettingsManager.swift` | Switch logic: scrub managed keys from settings.json, merge profile data |
| `ClaudeProfileSwitcher/Sources/Views/ProfileListView.swift` | Sidebar list of profiles with selection |
| `ClaudeProfileSwitcher/Sources/Views/ProfileFormView.swift` | Edit form with all fields |
| `ClaudeProfileSwitcher/Sources/Views/ManageView.swift` | Two-column layout combining list + form |
| `ClaudeProfileSwitcher/scripts/create-app-bundle.sh` | Builds `.app` bundle from compiled binary |

---

### Task 1: Scaffold Swift Package

**Files:**
- Create: `ClaudeProfileSwitcher/Package.swift`
- Create: `ClaudeProfileSwitcher/Sources/App.swift`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p ClaudeProfileSwitcher/Sources/Models
mkdir -p ClaudeProfileSwitcher/Sources/Services
mkdir -p ClaudeProfileSwitcher/Sources/Views
mkdir -p ClaudeProfileSwitcher/scripts
```

- [ ] **Step 2: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeProfileSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClaudeProfileSwitcher",
            path: "Sources"
        )
    ]
)
```

- [ ] **Step 3: Create minimal App.swift**

```swift
import SwiftUI

@main
struct ClaudeProfileSwitcherApp: App {
    var body: some Scene {
        MenuBarExtra("Claude", systemImage: "cpu") {
            Text("Hello")
        }
        .menuBarExtraStyle(.menu)
    }
}
```

- [ ] **Step 4: Verify it builds and runs**

```bash
cd ClaudeProfileSwitcher
swift build
```

Expected: Build succeeds with no errors.

- [ ] **Step 5: Commit**

```bash
git add ClaudeProfileSwitcher/
git commit -m "feat: scaffold SwiftUI menu bar app package"
```

---

### Task 2: Profile Model

**Files:**
- Create: `ClaudeProfileSwitcher/Sources/Models/Profile.swift`

- [ ] **Step 1: Create Profile.swift with Codable model and flat-field representation**

```swift
import Foundation

struct Profile: Codable, Identifiable, Hashable {
    var id: String { name }

    var name: String
    var model: String
    var baseUrl: String
    var apiKey: String
    var sonnetModel: String
    var opusModel: String
    var haikuModel: String

    /// The JSON format stored on disk
    struct DiskFormat: Codable {
        var model: String?
        var customModels: [String: String]?
        var env: [String: String]?
    }

    /// Create a new blank profile
    static func blank(name: String = "New Profile") -> Profile {
        Profile(
            name: name,
            model: "",
            baseUrl: "https://api.anthropic.com",
            apiKey: "",
            sonnetModel: "",
            opusModel: "",
            haikuModel: ""
        )
    }

    /// Convert to disk format for saving
    func toDiskFormat() -> DiskFormat {
        var env: [String: String] = [:]
        if !baseUrl.isEmpty { env["ANTHROPIC_BASE_URL"] = baseUrl }
        if !apiKey.isEmpty {
            env["ANTHROPIC_API_KEY"] = apiKey
            env["ANTHROPIC_AUTH_TOKEN"] = apiKey
        }
        if !sonnetModel.isEmpty { env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = sonnetModel }
        if !opusModel.isEmpty { env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = opusModel }
        if !haikuModel.isEmpty { env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = haikuModel }

        return DiskFormat(
            model: model.isEmpty ? nil : model,
            customModels: nil,
            env: env.isEmpty ? nil : env
        )
    }

    /// Create from disk format
    static func fromDiskFormat(name: String, data: DiskFormat) -> Profile {
        let env = data.env ?? [:]
        let custom = data.customModels ?? [:]
        return Profile(
            name: name,
            model: data.model ?? "",
            baseUrl: env["ANTHROPIC_BASE_URL"] ?? "",
            apiKey: env["ANTHROPIC_API_KEY"] ?? "",
            sonnetModel: env["ANTHROPIC_DEFAULT_SONNET_MODEL"]
                ?? custom["claude-3-5-sonnet-20241022"] ?? "",
            opusModel: env["ANTHROPIC_DEFAULT_OPUS_MODEL"]
                ?? custom["claude-3-opus-20240229"] ?? "",
            haikuModel: env["ANTHROPIC_DEFAULT_HAIKU_MODEL"]
                ?? custom["claude-3-5-haiku-20241022"] ?? ""
        )
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
cd ClaudeProfileSwitcher && swift build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add ClaudeProfileSwitcher/Sources/Models/Profile.swift
git commit -m "feat: add Profile model with disk format conversion"
```

---

### Task 3: ProfileStore Service

**Files:**
- Create: `ClaudeProfileSwitcher/Sources/Services/ProfileStore.swift`

- [ ] **Step 1: Create ProfileStore.swift**

```swift
import Foundation
import Combine

@MainActor
class ProfileStore: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var currentProfileName: String = ""

    private let claudeDir: URL
    private let profilesDir: URL
    private let currentProfileFile: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        claudeDir = home.appendingPathComponent(".claude")
        profilesDir = claudeDir.appendingPathComponent("profiles")
        currentProfileFile = claudeDir.appendingPathComponent(".current_profile")
        loadProfiles()
        loadCurrentProfile()
    }

    // MARK: - Read

    func loadProfiles() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: profilesDir,
            includingPropertiesForKeys: nil
        ) else { return }

        profiles = files
            .filter { $0.pathExtension == "json" }
            .compactMap { file -> Profile? in
                guard let data = try? Data(contentsOf: file),
                      let disk = try? JSONDecoder().decode(Profile.DiskFormat.self, from: data)
                else { return nil }
                let name = file.deletingPathExtension().lastPathComponent
                return Profile.fromDiskFormat(name: name, data: disk)
            }
            .sorted { $0.name < $1.name }
    }

    func loadCurrentProfile() {
        if let text = try? String(contentsOf: currentProfileFile, encoding: .utf8) {
            currentProfileName = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    // MARK: - Write

    func save(_ profile: Profile) {
        let fm = FileManager.default
        try? fm.createDirectory(at: profilesDir, withIntermediateDirectories: true)

        let file = profilesDir.appendingPathComponent("\(profile.name).json")
        let disk = profile.toDiskFormat()
        if let data = try? JSONEncoder().encode(disk) {
            try? data.write(to: file, options: .atomic)
        }
        loadProfiles()
    }

    func delete(name: String) {
        let file = profilesDir.appendingPathComponent("\(name).json")
        try? FileManager.default.removeItem(at: file)
        loadProfiles()
    }

    func setCurrentProfile(_ name: String) {
        try? name.write(
            to: currentProfileFile,
            atomically: true,
            encoding: .utf8
        )
        currentProfileName = name
    }

    func safeName(for input: String) -> String {
        let safe = input.lowercased()
            .map { $0.isLetter || $0.isNumber ? $0 : "-" }
            .map { String($0) }
            .joined()
        let collapsed = safe
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed.isEmpty ? "default" : collapsed
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
cd ClaudeProfileSwitcher && swift build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add ClaudeProfileSwitcher/Sources/Services/ProfileStore.swift
git commit -m "feat: add ProfileStore service for CRUD on profile files"
```

---

### Task 4: SettingsManager Service

**Files:**
- Create: `ClaudeProfileSwitcher/Sources/Services/SettingsManager.swift`

- [ ] **Step 1: Create SettingsManager.swift — port the scrub-and-merge logic from the Python script**

```swift
import Foundation

struct SettingsManager {
    private let claudeDir: URL
    private let settingsFile: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        claudeDir = home.appendingPathComponent(".claude")
        settingsFile = claudeDir.appendingPathComponent("settings.json")
    }

    private let managedRootKeys: Set<String> = [
        "model", "customModels", "systemPrompt"
    ]

    private let managedEnvKeys: Set<String> = [
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_BASE_URL",
        "ANTHROPIC_DEFAULT_SONNET_MODEL",
        "ANTHROPIC_DEFAULT_OPUS_MODEL",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL"
    ]

    /// Apply a profile to settings.json: scrub managed keys, merge profile data, write.
    func apply(profile: Profile, store: ProfileStore) {
        let fm = FileManager.default

        // Read existing settings
        var settings: [String: Any] = [:]
        if let data = try? Data(contentsOf: settingsFile),
           let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = decoded
        }

        // Backup
        if fm.fileExists(atPath: settingsFile.path) {
            let backup = claudeDir.appendingPathComponent("settings.json.bak")
            try? fm.copyItem(at: settingsFile, to: backup)
        }

        // Scrub managed root keys
        for key in managedRootKeys {
            settings.removeValue(forKey: key)
        }

        // Scrub managed env keys
        if settings["env"] is [String: Any] {
            var env = settings["env"] as! [String: Any]
            for key in managedEnvKeys {
                env.removeValue(forKey: key)
            }
            settings["env"] = env
        }

        // Merge profile data
        let disk = profile.toDiskFormat()
        if let customModels = disk.customModels {
            settings["customModels"] = customModels
        }
        if let model = disk.model {
            settings["model"] = model
        }
        if let profileEnv = disk.env {
            var env = (settings["env"] as? [String: Any]) ?? [:]
            env.merge(profileEnv) { _, new in new }
            settings["env"] = env
        }

        // Write
        if let data = try? JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            try? data.write(to: settingsFile, options: .atomic)
        }

        // Track current profile
        store.setCurrentProfile(profile.name)
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
cd ClaudeProfileSwitcher && swift build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add ClaudeProfileSwitcher/Sources/Services/SettingsManager.swift
git commit -m "feat: add SettingsManager with scrub-and-merge profile switching"
```

---

### Task 5: Profile List View (Sidebar)

**Files:**
- Create: `ClaudeProfileSwitcher/Sources/Views/ProfileListView.swift`

- [ ] **Step 1: Create ProfileListView.swift**

```swift
import SwiftUI

struct ProfileListView: View {
    @ObservedObject var store: ProfileStore
    @Binding var selectedProfileName: String?

    var body: some View {
        List(store.profiles, selection: $selectedProfileName) {
            profile in
            HStack(spacing: 8) {
                if profile.name == store.currentProfileName {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                Text(profile.name.capitalized)
                    .lineLimit(1)
                Spacer()
            }
            .tag(profile.name)
            .contextMenu {
                Button("Delete", role: .destructive) {
                    store.delete(name: profile.name)
                    if selectedProfileName == profile.name {
                        selectedProfileName = store.profiles.first?.name
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .overlay(alignment: .bottom) {
            HStack {
                Spacer()
                Button {
                    let newProfile = Profile.blank(name: "new-profile")
                    store.save(newProfile)
                    selectedProfileName = newProfile.name
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .padding(8)
            }
        }
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
cd ClaudeProfileSwitcher && swift build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add ClaudeProfileSwitcher/Sources/Views/ProfileListView.swift
git commit -m "feat: add profile list sidebar view"
```

---

### Task 6: Profile Form View

**Files:**
- Create: `ClaudeProfileSwitcher/Sources/Views/ProfileFormView.swift`

- [ ] **Step 1: Create ProfileFormView.swift with all fields, Save, and Delete**

```swift
import SwiftUI

struct ProfileFormView: View {
    @ObservedObject var store: ProfileStore
    @Binding var profile: Profile

    @State private var draft: Profile
    @State private var showDeleteConfirmation = false
    @State private var showSuccessMessage = false

    init(store: ProfileStore, profile: Binding<Profile>) {
        self.store = store
        _profile = profile
        _draft = State(initialValue: profile.wrappedValue)
    }

    private var hasChanges: Bool {
        draft.model != profile.model
            || draft.baseUrl != profile.baseUrl
            || draft.apiKey != profile.apiKey
            || draft.sonnetModel != profile.sonnetModel
            || draft.opusModel != profile.opusModel
            || draft.haikuModel != profile.haikuModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Connection Section
                GroupBox("Connection") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledField("Base URL") {
                            TextField("https://api.anthropic.com", text: $draft.baseUrl)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledField("API Token") {
                            SecureField("sk-...", text: $draft.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(8)
                }

                // Model Mapping Section
                GroupBox("Model Mappings") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledField("Sonnet") {
                            TextField("e.g. claude-3-5-sonnet-20241022", text: $draft.sonnetModel)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledField("Opus") {
                            TextField("e.g. claude-3-opus-20240229", text: $draft.opusModel)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledField("Haiku") {
                            TextField("e.g. claude-3-5-haiku-20241022", text: $draft.haikuModel)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(8)
                }

                // Actions
                HStack {
                    Button("Delete Profile", role: .destructive) {
                        showDeleteConfirmation = true
                    }

                    Spacer()

                    Button("Save") {
                        profile = draft
                        store.save(draft)
                        showSuccessMessage = true
                    }
                    .disabled(!hasChanges)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .alert("Profile Saved", isPresented: $showSuccessMessage) {
            Button("OK") {}
        }
        .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.delete(name: profile.name)
            }
        } message: {
            Text("This will permanently remove the profile \"\(profile.name.capitalized)\".")
        }
        .onChange(of: profile) { newProfile in
            draft = newProfile
        }
    }
}

private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content
        }
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
cd ClaudeProfileSwitcher && swift build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add ClaudeProfileSwitcher/Sources/Views/ProfileFormView.swift
git commit -m "feat: add profile form view with save/delete"
```

---

### Task 7: Manage View (Two-Column Layout)

**Files:**
- Create: `ClaudeProfileSwitcher/Sources/Views/ManageView.swift`

- [ ] **Step 1: Create ManageView.swift combining sidebar + form**

```swift
import SwiftUI

struct ManageView: View {
    @ObservedObject var store: ProfileStore
    @State private var selectedProfileName: String?

    private var selectedProfile: Binding<Profile?> {
        Binding(
            get: {
                guard let name = selectedProfileName else { return nil }
                return store.profiles.first { $0.name == name }
            },
            set: { newProfile in
                if let p = newProfile {
                    selectedProfileName = p.name
                }
            }
        )
    }

    var body: some View {
        NavigationSplitView {
            ProfileListView(
                store: store,
                selectedProfileName: $selectedProfileName
            )
            .frame(minWidth: 160)
        } detail: {
            if let profile = selectedProfile.wrappedValue {
                let binding = Binding<Profile>(
                    get: { profile },
                    set: { _ in }
                )
                ProfileFormView(store: store, profile: binding)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Select a profile")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 580, minHeight: 400)
        .onAppear {
            if selectedProfileName == nil {
                selectedProfileName = store.profiles.first?.name
            }
        }
    }
}
```

- [ ] **Step 2: Verify it builds**

```bash
cd ClaudeProfileSwitcher && swift build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add ClaudeProfileSwitcher/Sources/Views/ManageView.swift
git commit -m "feat: add two-column manage view layout"
```

---

### Task 8: Wire Up App Entry Point

**Files:**
- Modify: `ClaudeProfileSwitcher/Sources/App.swift`

- [ ] **Step 1: Replace App.swift with full implementation — menu bar menu + Window for management**

```swift
import SwiftUI

@main
struct ClaudeProfileSwitcherApp: App {
    @StateObject private var store = ProfileStore()
    private let settingsManager = SettingsManager()

    var body: some Scene {
        // Menu bar dropdown — profile switching
        MenuBarExtra {
            menuContent
        } label: {
            Label(store.currentProfileName.capitalized, systemImage: "cpu")
        }
        .menuBarExtraStyle(.menu)

        // Management window
        Window("Claude Profile Switcher", id: "manage") {
            ManageView(store: store)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 420)
    }

    @ViewBuilder
    private var menuContent: some View {
        // Profile list
        ForEach(store.profiles) { profile in
            Button {
                settingsManager.apply(profile: profile, store: store)
                store.loadProfiles()
            } label: {
                HStack {
                    if profile.name == store.currentProfileName {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(profile.name.capitalized)
                }
            }
        }

        Divider()

        Button {
            // Open the management window
            if #available(macOS 14.0, *) {
                openWindow(id: "manage")
            } else {
                // macOS 13 fallback
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "manage")
            }
        } label: {
            Label("Manage Profiles...", systemImage: "gearshape")
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
```

- [ ] **Step 2: Build and run the app**

```bash
cd ClaudeProfileSwitcher && swift build && swift run
```

Expected: App launches, menu bar icon appears showing current profile name. Dropdown shows profiles. Clicking a profile switches it. "Manage Profiles..." opens a window with sidebar + form.

- [ ] **Step 3: Test switching between profiles**

Click each profile in the dropdown. Verify that `~/.claude/settings.json` updates correctly and `~/.claude/.current_profile` reflects the selected profile.

- [ ] **Step 4: Test management window**

Click "Manage Profiles...". Verify the sidebar lists profiles, the form shows fields pre-filled with current values, Save updates the file, and Delete removes the profile.

- [ ] **Step 5: Commit**

```bash
git add ClaudeProfileSwitcher/Sources/App.swift
git commit -m "feat: wire up menu bar menu and management window"
```

---

### Task 9: App Bundle Script

**Files:**
- Create: `ClaudeProfileSwitcher/scripts/create-app-bundle.sh`

- [ ] **Step 1: Create the app bundle script**

```bash
#!/bin/bash
set -e

APP_NAME="ClaudeProfileSwitcher"
BUILD_DIR=".build/release"
BUNDLE_DIR="${APP_NAME}.app"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${BUNDLE_DIR}/Contents/MacOS/"

cat > "${BUNDLE_DIR}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClaudeProfileSwitcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.claude.profile-switcher</string>
    <key>CFBundleName</key>
    <string>Claude Profile Switcher</string>
    <key>CFBundleDisplayName</key>
    <string>Claude Profile Switcher</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
PLIST

echo "Created ${BUNDLE_DIR}"
echo "Install with: cp -r ${BUNDLE_DIR} /Applications/"
```

Note: `LSUIElement` set to `true` is what hides the Dock icon.

- [ ] **Step 2: Make it executable and test**

```bash
chmod +x ClaudeProfileSwitcher/scripts/create-app-bundle.sh
cd ClaudeProfileSwitcher && ./scripts/create-app-bundle.sh
```

Expected: `ClaudeProfileSwitcher.app` is created in the project directory.

- [ ] **Step 3: Install and test the app**

```bash
cp -r ClaudeProfileSwitcher.app /Applications/
open /Applications/ClaudeProfileSwitcher.app
```

Expected: App appears in menu bar, no Dock icon.

- [ ] **Step 4: Commit**

```bash
git add ClaudeProfileSwitcher/scripts/
git commit -m "feat: add app bundle creation script"
```

---

### Task 10: Cleanup — Remove SwiftBar Plugin

**Files:**
- Remove: `~/Documents/SwiftBar/plugins/claude-profiles.10s.py` (user action)

- [ ] **Step 1: Remove the old SwiftBar plugin**

```bash
rm ~/Documents/SwiftBar/plugins/claude-profiles.10s.py
```

- [ ] **Step 2: Verify the new app works end-to-end**

1. Open the app from `/Applications/ClaudeProfileSwitcher.app`
2. Verify menu bar icon shows current profile name
3. Switch profiles via dropdown — check `~/.claude/settings.json` updates
4. Open "Manage Profiles..." — verify list shows all profiles
5. Edit a profile and Save — verify JSON file updates
6. Add a new profile — verify it appears in both menu and management window
7. Delete a profile — verify it's removed from disk

- [ ] **Step 3: (Optional) Set auto-launch at login**

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/ClaudeProfileSwitcher.app", hidden:true}'
```

- [ ] **Step 4: Commit the final state**

```bash
git add -A
git commit -m "chore: cleanup SwiftBar plugin, finalize native app"
```
