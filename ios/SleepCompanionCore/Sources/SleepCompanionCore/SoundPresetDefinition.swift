import Foundation

public struct SoundPresetDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var description: String
    public var parameters: SoundParameters
    public var audioAssetName: String?

    public init(
        id: String,
        title: String,
        description: String,
        parameters: SoundParameters,
        audioAssetName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.parameters = parameters.clamped()
        self.audioAssetName = audioAssetName
    }

    public static let customDraftPresetID = "custom-draft"

    public static let defaultPreset = SoundPresetDefinition(
        id: "deep-fan",
        title: "Deep Fan",
        description: "The Web Audio proof-of-concept tone: fan-like airflow, low rumble, soft hum, and a restrained green layer.",
        parameters: SoundParameters(
            level: 0.42,
            greenMix: 0.25,
            fanAir: 0.55,
            fanRumble: 0.65,
            fanHum: 0.52,
            fanHumPitch: 92,
            fanDrift: 0.32,
            warmth: 0.35,
            lowCut: 0,
            highCut: 1,
            width: 1
        )
    )

    public static let bundledPresets: [SoundPresetDefinition] = [
        defaultPreset,
        SoundPresetDefinition(
            id: "soft-green",
            title: "Soft Green",
            description: "A calmer procedural bed with less fan hum and a stronger mid-band green layer.",
            parameters: SoundParameters(
                level: 0.36,
                greenMix: 0.58,
                fanAir: 0.42,
                fanRumble: 0.32,
                fanHum: 0.18,
                fanHumPitch: 76,
                fanDrift: 0.22,
                warmth: 0.28,
                lowCut: 0.08,
                highCut: 0.74,
                width: 0.9
            )
        ),
        SoundPresetDefinition(
            id: "low-rumble",
            title: "Low Rumble",
            description: "A darker procedural fan profile with stronger low motion and minimal green texture.",
            parameters: SoundParameters(
                level: 0.4,
                greenMix: 0.08,
                fanAir: 0.34,
                fanRumble: 0.84,
                fanHum: 0.44,
                fanHumPitch: 58,
                fanDrift: 0.46,
                warmth: 0.62,
                lowCut: 0,
                highCut: 0.52,
                width: 0.78
            )
        )
    ]
}
