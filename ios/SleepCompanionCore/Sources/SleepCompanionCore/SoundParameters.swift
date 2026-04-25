import Foundation

public enum SoundParameterID: String, CaseIterable, Codable, Equatable, Hashable, Identifiable, Sendable {
    case level
    case greenMix
    case fanAir
    case fanRumble
    case fanHum
    case fanHumPitch
    case fanDrift
    case warmth
    case lowCut
    case highCut
    case width

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
        case .level, .fanAir, .fanRumble, .fanHum, .fanDrift, .warmth, .width:
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
            id: .greenMix,
            label: "Green Layer",
            group: .greenLayer,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.25
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
            id: .fanRumble,
            label: "Rumble",
            group: .fanBody,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.65
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
            id: .fanDrift,
            label: "Movement",
            group: .movement,
            minValue: 0,
            maxValue: 1,
            step: 0.01,
            defaultValue: 0.32
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
        ),
        SoundControlDefinition(
            id: .width,
            label: "Stereo Width",
            group: .output,
            minValue: 0,
            maxValue: 2,
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

public struct SoundParameters: Codable, Equatable, Sendable {
    public var level: Double
    public var greenMix: Double
    public var fanAir: Double
    public var fanRumble: Double
    public var fanHum: Double
    public var fanHumPitch: Double
    public var fanDrift: Double
    public var warmth: Double
    public var lowCut: Double
    public var highCut: Double
    public var width: Double

    public init(
        level: Double,
        greenMix: Double,
        fanAir: Double,
        fanRumble: Double,
        fanHum: Double,
        fanHumPitch: Double,
        fanDrift: Double,
        warmth: Double,
        lowCut: Double,
        highCut: Double,
        width: Double
    ) {
        self.level = level
        self.greenMix = greenMix
        self.fanAir = fanAir
        self.fanRumble = fanRumble
        self.fanHum = fanHum
        self.fanHumPitch = fanHumPitch
        self.fanDrift = fanDrift
        self.warmth = warmth
        self.lowCut = lowCut
        self.highCut = highCut
        self.width = width
    }

    public func clamped() -> SoundParameters {
        SoundParameters(
            level: Self.clamp(level, min: 0, max: 1),
            greenMix: Self.clamp(greenMix, min: 0, max: 1),
            fanAir: Self.clamp(fanAir, min: 0, max: 1),
            fanRumble: Self.clamp(fanRumble, min: 0, max: 1),
            fanHum: Self.clamp(fanHum, min: 0, max: 1),
            fanHumPitch: Self.clamp(fanHumPitch, min: 40, max: 130),
            fanDrift: Self.clamp(fanDrift, min: 0, max: 1),
            warmth: Self.clamp(warmth, min: 0, max: 1),
            lowCut: Self.clamp(lowCut, min: 0, max: 1),
            highCut: Self.clamp(highCut, min: 0, max: 1),
            width: Self.clamp(width, min: 0, max: 2)
        )
    }

    public subscript(id: SoundParameterID) -> Double {
        get {
            switch id {
            case .level: level
            case .greenMix: greenMix
            case .fanAir: fanAir
            case .fanRumble: fanRumble
            case .fanHum: fanHum
            case .fanHumPitch: fanHumPitch
            case .fanDrift: fanDrift
            case .warmth: warmth
            case .lowCut: lowCut
            case .highCut: highCut
            case .width: width
            }
        }
        set {
            let value = SoundControlDefinition.definition(for: id).clampedValue(newValue)

            switch id {
            case .level:
                level = value
            case .greenMix:
                greenMix = value
            case .fanAir:
                fanAir = value
            case .fanRumble:
                fanRumble = value
            case .fanHum:
                fanHum = value
            case .fanHumPitch:
                fanHumPitch = value
            case .fanDrift:
                fanDrift = value
            case .warmth:
                warmth = value
            case .lowCut:
                lowCut = value
            case .highCut:
                highCut = value
            case .width:
                width = value
            }
        }
    }

    public static var defaultControlValues: SoundParameters {
        SoundParameters(
            level: SoundControlDefinition.definition(for: .level).defaultValue,
            greenMix: SoundControlDefinition.definition(for: .greenMix).defaultValue,
            fanAir: SoundControlDefinition.definition(for: .fanAir).defaultValue,
            fanRumble: SoundControlDefinition.definition(for: .fanRumble).defaultValue,
            fanHum: SoundControlDefinition.definition(for: .fanHum).defaultValue,
            fanHumPitch: SoundControlDefinition.definition(for: .fanHumPitch).defaultValue,
            fanDrift: SoundControlDefinition.definition(for: .fanDrift).defaultValue,
            warmth: SoundControlDefinition.definition(for: .warmth).defaultValue,
            lowCut: SoundControlDefinition.definition(for: .lowCut).defaultValue,
            highCut: SoundControlDefinition.definition(for: .highCut).defaultValue,
            width: SoundControlDefinition.definition(for: .width).defaultValue
        )
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(max, Swift.max(min, value))
    }
}
