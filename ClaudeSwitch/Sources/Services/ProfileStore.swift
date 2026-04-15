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
}
