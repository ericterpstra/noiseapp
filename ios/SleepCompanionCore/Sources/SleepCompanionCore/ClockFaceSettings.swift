import Foundation

public enum ClockFontID: String, Codable, CaseIterable, Equatable, Sendable {
    case rounded
    case monospaced
    case system
    case serif
}

public struct ClockFaceSettings: Codable, Equatable, Sendable {
    public var fontID: ClockFontID
    public var colorHex: String
    public var size: Double
    public var luminosity: Double

    public init(
        fontID: ClockFontID,
        colorHex: String,
        size: Double,
        luminosity: Double
    ) {
        self.fontID = fontID
        self.colorHex = colorHex
        self.size = Self.clamp(size, min: 72, max: 220)
        self.luminosity = Self.clamp(luminosity, min: 0.04, max: 1)
    }

    public static let `default` = ClockFaceSettings(
        fontID: .rounded,
        colorHex: "#F8F2E7",
        size: 132,
        luminosity: 0.42
    )

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(max, Swift.max(min, value))
    }
}
