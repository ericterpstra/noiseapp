import Foundation

public struct AppSettingsStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> AppSettings {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .default
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            return .default
        }
    }

    public func save(_ settings: AppSettings) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder.sleepCompanion.encode(settings)
        try data.write(to: fileURL, options: [.atomic])
    }
}

private extension JSONEncoder {
    static var sleepCompanion: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
