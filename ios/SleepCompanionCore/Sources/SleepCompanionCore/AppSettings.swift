import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var clockFace: ClockFaceSettings
    public var activeSoundPresetID: String
    public var activeSavedPresetID: String?
    public var activeSoundParameters: SoundParameters
    public var wakeTime: WakeTime
    public var hasCompletedWakeTransition: Bool

    public init(
        clockFace: ClockFaceSettings,
        activeSoundPresetID: String,
        activeSavedPresetID: String? = nil,
        activeSoundParameters: SoundParameters,
        wakeTime: WakeTime,
        hasCompletedWakeTransition: Bool
    ) {
        self.clockFace = clockFace
        self.activeSoundPresetID = activeSoundPresetID
        self.activeSavedPresetID = activeSavedPresetID
        self.activeSoundParameters = activeSoundParameters.clamped()
        self.wakeTime = wakeTime
        self.hasCompletedWakeTransition = hasCompletedWakeTransition
    }

    public static let `default` = AppSettings(
        clockFace: .default,
        activeSoundPresetID: SoundPresetDefinition.defaultPreset.id,
        activeSoundParameters: SoundPresetDefinition.defaultPreset.parameters,
        wakeTime: WakeTime(hour: 7, minute: 0),
        hasCompletedWakeTransition: false
    )
}

public struct SettingsDraft: Equatable, Sendable {
    public let originalSettings: AppSettings
    public private(set) var settings: AppSettings

    public init(settings: AppSettings) {
        self.originalSettings = settings
        self.settings = settings
    }

    public mutating func selectSoundPreset(id: String) {
        guard let preset = SoundPresetDefinition.bundledPresets.first(where: { $0.id == id }) else {
            return
        }

        settings.activeSoundPresetID = preset.id
        settings.activeSavedPresetID = nil
        settings.activeSoundParameters = preset.parameters
    }

    public mutating func setSoundParameter(_ id: SoundParameterID, value: Double) {
        settings.activeSoundPresetID = SoundPresetDefinition.customDraftPresetID
        settings.activeSoundParameters[id] = value
    }

    public mutating func setClockFace(_ clockFace: ClockFaceSettings) {
        settings.clockFace = clockFace
    }

    public mutating func loadSavedPreset(_ preset: SavedPresetDefinition) {
        settings.activeSavedPresetID = preset.id
        settings.activeSoundPresetID = preset.sourceSoundPresetID ?? SoundPresetDefinition.customDraftPresetID
        settings.activeSoundParameters = preset.soundParameters
    }

    public mutating func clearSavedPresetAssociation() {
        settings.activeSavedPresetID = nil
    }

    public mutating func setWakeTime(_ wakeTime: WakeTime) {
        settings.wakeTime = wakeTime
        settings.hasCompletedWakeTransition = false
    }

    public func appliedSettings() -> AppSettings {
        settings
    }

    public func cancelledSettings() -> AppSettings {
        originalSettings
    }
}
