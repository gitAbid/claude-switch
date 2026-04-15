import SwiftUI

@main
struct ClaudeSwitchApp: App {
    @StateObject private var store = ProfileStore()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            menuContent
        } label: {
            HStack(spacing: 4) {
                Image(nsImage: Self.statusBarIcon)
                if !store.currentProfileName.isEmpty {
                    Text(store.currentProfileName.capitalized)
                }
            }
        }
        .menuBarExtraStyle(.menu)

        Window("ClaudeSwitch", id: "manage") {
            ManageView(store: store)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 420)
    }

    @ViewBuilder
    private var menuContent: some View {
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
            openWindow(id: "manage")
            
            // Force app activation and window foregrounding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.title == "ClaudeSwitch" {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
            }
        } label: {
            Label("Manage Profiles...", systemImage: "gearshape")
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }

    private let settingsManager = SettingsManager()

    private static let statusBarIcon: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image: NSImage

        // SwiftPM bundles resources in a nested resource bundle
        let resourceBundle = Bundle.main
        let iconURL: URL?
        if let bundleURL = resourceBundle.url(forResource: "ClaudeSwitch_ClaudeSwitch", withExtension: "bundle"),
           let bundle = Bundle(url: bundleURL) {
            iconURL = bundle.url(forResource: "AppIcon", withExtension: "icns")
        } else {
            iconURL = resourceBundle.url(forResource: "AppIcon", withExtension: "icns")
        }

        if let url = iconURL, let loaded = NSImage(contentsOf: url) {
            image = loaded
        } else {
            image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "Profile")!
        }
        image.size = size
        image.isTemplate = false
        return image
    }()
}
