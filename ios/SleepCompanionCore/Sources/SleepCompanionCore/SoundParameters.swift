import Foundation

public enum SoundParameterID: String, CaseIterable, Codable, Equatable, Hashable, Identifiable, Sendable {
    case level
    case drive
    case width
    case greenMix
    case greenColor
    case fanAir
    case airTexture
    case airColor
    case fanRumble
    case rumbleColor
    case fanHum
    case fanHumPitch
    case humHarmonics
    case fanDrift
    case movementSpeed
    case warmth
    case bassBoost
    case trebleDamping
    case lowCut
    case highCut

    public var id: String { rawValue }
}

public enum SoundControlGroup: String, CaseIterable, Codable, Equatable, Sendable {
    case output
    case fanBody
    case movement
    case tone
    case greenLayer

    public var title: String {
        switch self {
        case .output: "Output"
        case .fanBody: "Fan Body"
        case .movement: "Movement"
        case .tone: "Tone"
        case .greenLayer: "Green Layer"
        }
    }
}

public struct SoundControlDefinition: Equatable, Identifiable, Sendable {
    public var id: SoundParameterID
    public var label: String
    public var group: SoundControlGroup
    public var minValue: Double
    public var maxValue: Double
    public var step: Double
    public var defaultValue: Double

    public init(
        id: SoundParameterID,
        label: String,
        group: SoundControlGroup,
        minValue: Double,
        maxValue: Double,
        step: Double,
        defaultValue: Double
    ) {
        self.id = id
        self.label = label
        self.group = group
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.defaultValue = defaultValue
    }

    public func formatValue(_ value: Double) -> String {
        let value = clampedValue(value)

        switch id {
        case .greenMix:
            return value <= 0 ? "Off" : Self.formatPercent(value)
        case .fanHumPitch:
            return Self.formatFrequency(value)
        case .lowCut:
            return Self.formatFrequency(FrequencyMapping.logFrequency(value: value, min: 20, max: 1_500))
        case .highCut:
            return Self.formatFrequency(FrequencyMapping.logFrequency(value: value, min: 1_200, max: 20_000))
        case .level, .drive, .width, .greenColor, .fanAir, .airTexture, .airColor, .fanRumble, .rumbleColor,
                .fanHum, .humHarmonics, .fanDrift, .movementSpeed, .warmth, .bassBoost, .trebleDamping:
            return Self.formatPercent(value)
        }
    }

    public func clampedValue(_ value: Double) -> Double {
        Swift.min(maxValue, Swift.max(minValue, value))
    }

    public static func definition(for id: SoundParameterID) -> SoundControlDefinition {
        allByID[id]!
    }

    public static func definitions(in group: SoundControlGroup) -> [SoundControlDefinition] {
        all.filter { $0.group == group }
    }

    public static let all: [SoundControlDefinition] = [
        SoundControlDefinition(
            id: .level,
            label: "Output Level",
            group: .output,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.42
        ),
        SoundControlDefinition(
            id: .drive,
            label: "Drive",
            group: .output,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.42
        ),
        SoundControlDefinition(
            id: .width,
            label: "Stereo Width",
            group: .output,
            minValue: 0,
            maxValue: 2,
            step: 0.01,
            defaultValue: 1
        ),
        SoundControlDefinition(
            id: .greenMix,
            label: "Green Layer",
            group: .greenLayer,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.25
        ),
        SoundControlDefinition(
            id: .greenColor,
            label: "Green Color",
            group: .greenLayer,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.5
        ),
        SoundControlDefinition(
            id: .fanAir,
            label: "Airflow",
            group: .fanBody,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.55
        ),
        SoundControlDefinition(
            id: .airTexture,
            label: "Air Texture",
            group: .fanBody,
            minValue: 0,
            maxValue: 0.35,
            step: 0.01,
            defaultValue: 0.08
        ),
        SoundControlDefinition(
            id: .airColor,
            label: "Air Color",
            group: .fanBody,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.5
        ),
        SoundControlDefinition(
            id: .fanRumble,
            label: "Rumble",
            group: .fanBody,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.65
        ),
        SoundControlDefinition(
            id: .rumbleColor,
            label: "Rumble Color",
            group: .fanBody,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.5
        ),
        SoundControlDefinition(
            id: .fanHum,
            label: "Hum",
            group: .fanBody,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.52
        ),
        SoundControlDefinition(
            id: .fanHumPitch,
            label: "Hum Pitch",
            group: .fanBody,
            minValue: 40,
            maxValue: 130,
            step: 1,
            defaultValue: 92
        ),
        SoundControlDefinition(
            id: .humHarmonics,
            label: "Hum Harmonics",
            group: .fanBody,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.5
        ),
        SoundControlDefinition(
            id: .fanDrift,
            label: "Movement",
            group: .movement,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.32
        ),
        SoundControlDefinition(
            id: .movementSpeed,
            label: "Movement Speed",
            group: .movement,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.5
        ),
        SoundControlDefinition(
            id: .warmth,
            label: "Warmth",
            group: .tone,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.35
        ),
        SoundControlDefinition(
            id: .bassBoost,
            label: "Bass Boost",
            group: .tone,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.35
        ),
        SoundControlDefinition(
            id: .trebleDamping,
            label: "Treble Damping",
            group: .tone,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.35
        ),
        SoundControlDefinition(
            id: .lowCut,
            label: "Low Cut",
            group: .tone,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0
        ),
        SoundControlDefinition(
            id: .highCut,
            label: "High Cut",
            group: .tone,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 1
        )
    ]

    private static let allByID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    private static func formatPercent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func formatFrequency(_ value: Double) -> String {
        guard value >= 1_000 else {
            return "\(Int(value.rounded())) Hz"
        }

        let decimals = value >= 10_000 ? 1 : 2
        var text = String(format: "%.\(decimals)f", value / 1_000)

        if text.hasSuffix(".0") {
            text.removeLast(2)
        }

        return "\(text) kHz"
    }
}

public enum SoundOutputMapping {
    public static func mixerOutputVolume(level: Double) -> Double {
        let level = clampedLevel(level)
        return pow(level, 1.15)
    }

    public static func renderDrive(level: Double) -> Double {
        renderDrive(drive: level)
    }

    public static func renderDrive(drive: Double) -> Double {
        let drive = clampedLevel(drive)
        return 1 + pow(drive, 1.35) * 1.9
    }

    private static func clampedLevel(_ level: Double) -> Double {
        Swift.min(1, Swift.max(0, level))
    }
}

public enum SoundFilterMapping {
    public static func airCutoffs(color: Double) -> (primary: Double, secondary: Double) {
        let color = clampedUnit(color)
        return (
            primary: FrequencyMapping.logFrequency(value: color, min: 350, max: 1_400),
            secondary: FrequencyMapping.logFrequency(value: color, min: 210, max: 840)
        )
    }

    public static func rumbleCutoffs(color: Double) -> (primary: Double, secondary: Double) {
        let color = clampedUnit(color)
        return (
            primary: FrequencyMapping.logFrequency(value: color, min: 57.5, max: 230),
            secondary: FrequencyMapping.logFrequency(value: color, min: 24, max: 96)
        )
    }

    public static func greenBandCutoffs(color: Double) -> (low: Double, high: Double) {
        let color = clampedUnit(color)
        return (
            low: FrequencyMapping.logFrequency(value: color, min: 80, max: 605),
            high: FrequencyMapping.logFrequency(value: color, min: 900, max: 3_600)
        )
    }

    public static func movementRateScale(speed: Double) -> Double {
        0.45 + clampedUnit(speed) * 1.1
    }

    public static func humHarmonicScale(harmonics: Double) -> Double {
        clampedUnit(harmonics) * 2
    }

    private static func clampedUnit(_ value: Double) -> Double {
        Swift.min(1, Swift.max(0, value))
    }
}

public struct SoundParameters: Codable, Equatable, Sendable {
    public var level: Double
    public var drive: Double
    public var width: Double
    public var greenMix: Double
    public var greenColor: Double
    public var fanAir: Double
    public var airTexture: Double
    public var airColor: Double
    public var fanRumble: Double
    public var rumbleColor: Double
    public var fanHum: Double
    public var fanHumPitch: Double
    public var humHarmonics: Double
    public var fanDrift: Double
    public var movementSpeed: Double
    public var warmth: Double
    public var bassBoost: Double
    public var trebleDamping: Double
    public var lowCut: Double
    public var highCut: Double

    public init(
        level: Double,
        drive: Double = 0.42,
        greenMix: Double,
        greenColor: Double = 0.5,
        fanAir: Double,
        airTexture: Double = 0.08,
        airColor: Double = 0.5,
        fanRumble: Double,
        rumbleColor: Double = 0.5,
        fanHum: Double,
        fanHumPitch: Double,
        humHarmonics: Double = 0.5,
        fanDrift: Double,
        movementSpeed: Double = 0.5,
        warmth: Double,
        bassBoost: Double = 0.35,
        trebleDamping: Double = 0.35,
        lowCut: Double,
        highCut: Double,
        width: Double = 1
    ) {
        self.level = level
        self.drive = drive
        self.width = width
        self.greenMix = greenMix
        self.greenColor = greenColor
        self.fanAir = fanAir
        self.airTexture = airTexture
        self.airColor = airColor
        self.fanRumble = fanRumble
        self.rumbleColor = rumbleColor
        self.fanHum = fanHum
        self.fanHumPitch = fanHumPitch
        self.humHarmonics = humHarmonics
        self.fanDrift = fanDrift
        self.movementSpeed = movementSpeed
        self.warmth = warmth
        self.bassBoost = bassBoost
        self.trebleDamping = trebleDamping
        self.lowCut = lowCut
        self.highCut = highCut
    }

    public func clamped() -> SoundParameters {
        SoundParameters(
            level: Self.clamp(level, min: 0, max: 1),
            drive: Self.clamp(drive, min: 0, max: 1),
            greenMix: Self.clamp(greenMix, min: 0, max: 1),
            greenColor: Self.clamp(greenColor, min: 0, max: 1),
            fanAir: Self.clamp(fanAir, min: 0, max: 1),
            airTexture: Self.clamp(airTexture, min: 0, max: 0.35),
            airColor: Self.clamp(airColor, min: 0, max: 1),
            fanRumble: Self.clamp(fanRumble, min: 0, max: 1),
            rumbleColor: Self.clamp(rumbleColor, min: 0, max: 1),
            fanHum: Self.clamp(fanHum, min: 0, max: 1),
            fanHumPitch: Self.clamp(fanHumPitch, min: 40, max: 130),
            humHarmonics: Self.clamp(humHarmonics, min: 0, max: 1),
            fanDrift: Self.clamp(fanDrift, min: 0, max: 1),
            movementSpeed: Self.clamp(movementSpeed, min: 0, max: 1),
            warmth: Self.clamp(warmth, min: 0, max: 1),
            bassBoost: Self.clamp(bassBoost, min: 0, max: 1),
            trebleDamping: Self.clamp(trebleDamping, min: 0, max: 1),
            lowCut: Self.clamp(lowCut, min: 0, max: 1),
            highCut: Self.clamp(highCut, min: 0, max: 1),
            width: Self.clamp(width, min: 0, max: 2)
        )
    }

    public subscript(id: SoundParameterID) -> Double {
        get {
            switch id {
            case .level: level
            case .drive: drive
            case .width: width
            case .greenMix: greenMix
            case .greenColor: greenColor
            case .fanAir: fanAir
            case .airTexture: airTexture
            case .airColor: airColor
            case .fanRumble: fanRumble
            case .rumbleColor: rumbleColor
            case .fanHum: fanHum
            case .fanHumPitch: fanHumPitch
            case .humHarmonics: humHarmonics
            case .fanDrift: fanDrift
            case .movementSpeed: movementSpeed
            case .warmth: warmth
            case .bassBoost: bassBoost
            case .trebleDamping: trebleDamping
            case .lowCut: lowCut
            case .highCut: highCut
            }
        }
        set {
            let value = SoundControlDefinition.definition(for: id).clampedValue(newValue)

            switch id {
            case .level:
                level = value
            case .drive:
                drive = value
            case .width:
                width = value
            case .greenMix:
                greenMix = value
            case .greenColor:
                greenColor = value
            case .fanAir:
                fanAir = value
            case .airTexture:
                airTexture = value
            case .airColor:
                airColor = value
            case .fanRumble:
                fanRumble = value
            case .rumbleColor:
                rumbleColor = value
            case .fanHum:
                fanHum = value
            case .fanHumPitch:
                fanHumPitch = value
            case .humHarmonics:
                humHarmonics = value
            case .fanDrift:
                fanDrift = value
            case .movementSpeed:
                movementSpeed = value
            case .warmth:
                warmth = value
            case .bassBoost:
                bassBoost = value
            case .trebleDamping:
                trebleDamping = value
            case .lowCut:
                lowCut = value
            case .highCut:
                highCut = value
            }
        }
    }

    public static var defaultControlValues: SoundParameters {
        SoundParameters(
            level: SoundControlDefinition.definition(for: .level).defaultValue,
            drive: SoundControlDefinition.definition(for: .drive).defaultValue,
            greenMix: SoundControlDefinition.definition(for: .greenMix).defaultValue,
            greenColor: SoundControlDefinition.definition(for: .greenColor).defaultValue,
            fanAir: SoundControlDefinition.definition(for: .fanAir).defaultValue,
            airTexture: SoundControlDefinition.definition(for: .airTexture).defaultValue,
            airColor: SoundControlDefinition.definition(for: .airColor).defaultValue,
            fanRumble: SoundControlDefinition.definition(for: .fanRumble).defaultValue,
            rumbleColor: SoundControlDefinition.definition(for: .rumbleColor).defaultValue,
            fanHum: SoundControlDefinition.definition(for: .fanHum).defaultValue,
            fanHumPitch: SoundControlDefinition.definition(for: .fanHumPitch).defaultValue,
            humHarmonics: SoundControlDefinition.definition(for: .humHarmonics).defaultValue,
            fanDrift: SoundControlDefinition.definition(for: .fanDrift).defaultValue,
            movementSpeed: SoundControlDefinition.definition(for: .movementSpeed).defaultValue,
            warmth: SoundControlDefinition.definition(for: .warmth).defaultValue,
            bassBoost: SoundControlDefinition.definition(for: .bassBoost).defaultValue,
            trebleDamping: SoundControlDefinition.definition(for: .trebleDamping).defaultValue,
            lowCut: SoundControlDefinition.definition(for: .lowCut).defaultValue,
            highCut: SoundControlDefinition.definition(for: .highCut).defaultValue,
            width: SoundControlDefinition.definition(for: .width).defaultValue
        )
    }

    private enum CodingKeys: String, CodingKey {
        case level
        case drive
        case width
        case greenMix
        case greenColor
        case fanAir
        case airTexture
        case airColor
        case fanRumble
        case rumbleColor
        case fanHum
        case fanHumPitch
        case humHarmonics
        case fanDrift
        case movementSpeed
        case warmth
        case bassBoost
        case trebleDamping
        case lowCut
        case highCut
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaultControlValues
        let level = try container.decodeIfPresent(Double.self, forKey: .level) ?? defaults.level
        let warmth = try container.decodeIfPresent(Double.self, forKey: .warmth) ?? defaults.warmth

        self = SoundParameters(
            level: level,
            drive: try container.decodeIfPresent(Double.self, forKey: .drive) ?? level,
            greenMix: try container.decodeIfPresent(Double.self, forKey: .greenMix) ?? defaults.greenMix,
            greenColor: try container.decodeIfPresent(Double.self, forKey: .greenColor) ?? defaults.greenColor,
            fanAir: try container.decodeIfPresent(Double.self, forKey: .fanAir) ?? defaults.fanAir,
            airTexture: try container.decodeIfPresent(Double.self, forKey: .airTexture) ?? defaults.airTexture,
            airColor: try container.decodeIfPresent(Double.self, forKey: .airColor) ?? defaults.airColor,
            fanRumble: try container.decodeIfPresent(Double.self, forKey: .fanRumble) ?? defaults.fanRumble,
            rumbleColor: try container.decodeIfPresent(Double.self, forKey: .rumbleColor) ?? defaults.rumbleColor,
            fanHum: try container.decodeIfPresent(Double.self, forKey: .fanHum) ?? defaults.fanHum,
            fanHumPitch: try container.decodeIfPresent(Double.self, forKey: .fanHumPitch) ?? defaults.fanHumPitch,
            humHarmonics: try container.decodeIfPresent(Double.self, forKey: .humHarmonics) ?? defaults.humHarmonics,
            fanDrift: try container.decodeIfPresent(Double.self, forKey: .fanDrift) ?? defaults.fanDrift,
            movementSpeed: try container.decodeIfPresent(Double.self, forKey: .movementSpeed) ?? defaults.movementSpeed,
            warmth: warmth,
            bassBoost: try container.decodeIfPresent(Double.self, forKey: .bassBoost) ?? warmth,
            trebleDamping: try container.decodeIfPresent(Double.self, forKey: .trebleDamping) ?? warmth,
            lowCut: try container.decodeIfPresent(Double.self, forKey: .lowCut) ?? defaults.lowCut,
            highCut: try container.decodeIfPresent(Double.self, forKey: .highCut) ?? defaults.highCut,
            width: try container.decodeIfPresent(Double.self, forKey: .width) ?? defaults.width
        ).clamped()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(level, forKey: .level)
        try container.encode(drive, forKey: .drive)
        try container.encode(width, forKey: .width)
        try container.encode(greenMix, forKey: .greenMix)
        try container.encode(greenColor, forKey: .greenColor)
        try container.encode(fanAir, forKey: .fanAir)
        try container.encode(airTexture, forKey: .airTexture)
        try container.encode(airColor, forKey: .airColor)
        try container.encode(fanRumble, forKey: .fanRumble)
        try container.encode(rumbleColor, forKey: .rumbleColor)
        try container.encode(fanHum, forKey: .fanHum)
        try container.encode(fanHumPitch, forKey: .fanHumPitch)
        try container.encode(humHarmonics, forKey: .humHarmonics)
        try container.encode(fanDrift, forKey: .fanDrift)
        try container.encode(movementSpeed, forKey: .movementSpeed)
        try container.encode(warmth, forKey: .warmth)
        try container.encode(bassBoost, forKey: .bassBoost)
        try container.encode(trebleDamping, forKey: .trebleDamping)
        try container.encode(lowCut, forKey: .lowCut)
        try container.encode(highCut, forKey: .highCut)
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(max, Swift.max(min, value))
    }
}
