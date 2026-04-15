import Foundation

@MainActor
struct SettingsManager {
    private let claudeDir: URL
    private let settingsFile: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        claudeDir = home.appendingPathComponent(".claude")
        settingsFile = claudeDir.appendingPathComponent("settings.json")
    }

    private let managedEnvKeys: Set<String> = [
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_BASE_URL",
        "ANTHROPIC_DEFAULT_SONNET_MODEL",
        "ANTHROPIC_DEFAULT_OPUS_MODEL",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL"
    ]

    func apply(profile: Profile, store: ProfileStore) {
        let fm = FileManager.default

        var settings: [String: Any] = [:]
        if let data = try? Data(contentsOf: settingsFile),
           let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = decoded
        }

        // Backup
        if fm.fileExists(atPath: settingsFile.path) {
            let backup = claudeDir.appendingPathComponent("settings.json.bak")
            try? fm.removeItem(at: backup)
            try? fm.copyItem(at: settingsFile, to: backup)
        }

        // Scrub managed env keys
        if settings["env"] is [String: Any] {
            var env = settings["env"] as! [String: Any]
            for key in managedEnvKeys {
                env.removeValue(forKey: key)
            }
            settings["env"] = env
        }

        // Merge profile env
        let disk = profile.toDiskFormat()
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

        store.setCurrentProfile(profile.name)
    }
}
