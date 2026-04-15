import Foundation

enum AuthType: String, Codable, CaseIterable {
    case apiKey = "apiKey"
    case authToken = "authToken"

    var label: String {
        switch self {
        case .apiKey: return "API Key"
        case .authToken: return "Auth Token"
        }
    }

    var placeholder: String {
        switch self {
        case .apiKey: return "sk-..."
        case .authToken: return "token..."
        }
    }

    var envKey: String {
        switch self {
        case .apiKey: return "ANTHROPIC_API_KEY"
        case .authToken: return "ANTHROPIC_AUTH_TOKEN"
        }
    }
}

struct Profile: Codable, Identifiable, Hashable {
    var id: String { name }

    var name: String
    var baseUrl: String
    var authType: AuthType
    var token: String
    var sonnetModel: String
    var opusModel: String
    var haikuModel: String

    struct DiskFormat: Codable {
        var env: [String: String]?
    }

    static func blank(name: String = "New Profile") -> Profile {
        Profile(
            name: name,
            baseUrl: "https://api.anthropic.com",
            authType: .apiKey,
            token: "",
            sonnetModel: "",
            opusModel: "",
            haikuModel: ""
        )
    }

    func toDiskFormat() -> DiskFormat {
        var env: [String: String] = [:]
        if !baseUrl.isEmpty { env["ANTHROPIC_BASE_URL"] = baseUrl }
        if !token.isEmpty {
            env[authType.envKey] = token
        }
        if !sonnetModel.isEmpty { env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = sonnetModel }
        if !opusModel.isEmpty { env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = opusModel }
        if !haikuModel.isEmpty { env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = haikuModel }

        return DiskFormat(env: env.isEmpty ? nil : env)
    }

    static func fromDiskFormat(name: String, data: DiskFormat) -> Profile {
        let env = data.env ?? [:]

        let authToken = env["ANTHROPIC_AUTH_TOKEN"]
        let apiKey = env["ANTHROPIC_API_KEY"]
        let detectedAuthType: AuthType
        let detectedToken: String
        if let authToken, !authToken.isEmpty {
            detectedAuthType = .authToken
            detectedToken = authToken
        } else if let apiKey, !apiKey.isEmpty {
            detectedAuthType = .apiKey
            detectedToken = apiKey
        } else {
            detectedAuthType = .apiKey
            detectedToken = ""
        }

        return Profile(
            name: name,
            baseUrl: env["ANTHROPIC_BASE_URL"] ?? "",
            authType: detectedAuthType,
            token: detectedToken,
            sonnetModel: env["ANTHROPIC_DEFAULT_SONNET_MODEL"] ?? "",
            opusModel: env["ANTHROPIC_DEFAULT_OPUS_MODEL"] ?? "",
            haikuModel: env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] ?? ""
        )
    }
}
