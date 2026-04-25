import Foundation

public struct SavedPresetDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var description: String
    public var soundParameters: SoundParameters
    public var clockFace: ClockFaceSettings
    public var sourceSoundPresetID: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        title: String,
        description: String,
        soundParameters: SoundParameters,
        clockFace: ClockFaceSettings,
        sourceSoundPresetID: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.soundParameters = soundParameters.clamped()
        self.clockFace = clockFace
        self.sourceSoundPresetID = sourceSoundPresetID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct SavedPresetLibrary: Codable, Equatable, Sendable {
    public private(set) var presets: [SavedPresetDefinition]

    public init(presets: [SavedPresetDefinition] = []) {
        var seenIDs = Set<String>()
        self.presets = presets.filter { preset in
            guard !seenIDs.contains(preset.id) else {
                return false
            }

            seenIDs.insert(preset.id)
            return true
        }
    }

    public func preset(id: String) -> SavedPresetDefinition? {
        presets.first { $0.id == id }
    }

    public mutating func create(
        title: String,
        description: String,
        from settings: AppSettings,
        now: Date = Date(),
        makeID: () -> String = { UUID().uuidString }
    ) -> SavedPresetDefinition {
        let preset = SavedPresetDefinition(
            id: uniqueID(makeID: makeID),
            title: title,
            description: description,
            soundParameters: settings.activeSoundParameters,
            clockFace: settings.clockFace,
            sourceSoundPresetID: sourceSoundPresetID(from: settings),
            createdAt: now,
            updatedAt: now
        )

        presets.append(preset)
        return preset
    }

    public mutating func update(
        id: String,
        from settings: AppSettings,
        now: Date = Date()
    ) -> SavedPresetDefinition? {
        guard let index = presets.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        var preset = presets[index]
        preset.soundParameters = settings.activeSoundParameters.clamped()
        preset.clockFace = settings.clockFace
        preset.sourceSoundPresetID = sourceSoundPresetID(from: settings)
        preset.updatedAt = now
        presets[index] = preset
        return preset
    }

    public mutating func rename(
        id: String,
        title: String,
        description: String,
        now: Date = Date()
    ) -> SavedPresetDefinition? {
        guard let index = presets.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        presets[index].title = title
        presets[index].description = description
        presets[index].updatedAt = now
        return presets[index]
    }

    public mutating func duplicate(
        id: String,
        now: Date = Date(),
        makeID: () -> String = { UUID().uuidString }
    ) -> SavedPresetDefinition? {
        guard let index = presets.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        var preset = presets[index]
        preset.id = uniqueID(makeID: makeID)
        preset.title = "\(preset.title) Copy"
        preset.createdAt = now
        preset.updatedAt = now
        presets.insert(preset, at: presets.index(after: index))
        return preset
    }

    @discardableResult
    public mutating func delete(id: String) -> SavedPresetDefinition? {
        guard let index = presets.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        return presets.remove(at: index)
    }

    private func uniqueID(makeID: () -> String) -> String {
        let candidate = makeID()
        guard presets.contains(where: { $0.id == candidate }) else {
            return candidate
        }

        var fallback = UUID().uuidString
        while presets.contains(where: { $0.id == fallback }) {
            fallback = UUID().uuidString
        }
        return fallback
    }

    private func sourceSoundPresetID(from settings: AppSettings) -> String? {
        guard settings.activeSoundPresetID != SoundPresetDefinition.customDraftPresetID else {
            return nil
        }

        return settings.activeSoundPresetID
    }
}

public struct SavedPresetStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> SavedPresetLibrary {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return SavedPresetLibrary()
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(SavedPresetLibrary.self, from: data)
        } catch {
            return SavedPresetLibrary()
        }
    }

    public func save(_ library: SavedPresetLibrary) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder.sleepCompanion.encode(library)
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
