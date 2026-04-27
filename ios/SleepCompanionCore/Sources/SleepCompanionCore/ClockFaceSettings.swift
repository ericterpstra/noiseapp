import Foundation

public enum ClockFontID: String, Codable, CaseIterable, Equatable, Sendable {
    case rounded
    case monospaced
    case system
    case serif
    case avenirNextCondensed
    case dinAlternate
    case futura
    case gillSans
    case georgia
}

public enum ClockColorHex {
    public static let defaultText = "#F8F2E7"
    public static let defaultWakeBackground = "#FFFFFF"

    public static func normalized(_ hex: String, fallback: String) -> String {
        guard let components = rgbComponents(for: hex) else {
            return fallback
        }

        return String(
            format: "#%02X%02X%02X",
            Int((components.red * 255).rounded()),
            Int((components.green * 255).rounded()),
            Int((components.blue * 255).rounded())
        )
    }

    public static func relativeLuminance(_ hex: String) -> Double {
        guard let components = rgbComponents(for: hex) else {
            return 0
        }

        func linearized(_ component: Double) -> Double {
            component <= 0.03928
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        return linearized(components.red) * 0.2126
            + linearized(components.green) * 0.7152
            + linearized(components.blue) * 0.0722
    }

    public static func isLight(_ hex: String) -> Bool {
        relativeLuminance(hex) > 0.5
    }

    private static func rgbComponents(for hex: String) -> (red: Double, green: Double, blue: Double)? {
        let sanitized = hex
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            .uppercased()
        let validHexCharacters = CharacterSet(charactersIn: "0123456789ABCDEF")

        guard sanitized.count == 6,
              validHexCharacters.isSuperset(of: CharacterSet(charactersIn: sanitized)) else {
            return nil
        }

        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        return (
            red: Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >> 8) / 255,
            blue: Double(value & 0x0000FF) / 255
        )
    }
}

public struct ClockFaceSettings: Codable, Equatable, Sendable {
    public var fontID: ClockFontID
    public var colorHex: String
    public var size: Double
    public var luminosity: Double
    public var wakeBackgroundColorHex: String

    public init(
        fontID: ClockFontID,
        colorHex: String,
        size: Double,
        luminosity: Double,
        wakeBackgroundColorHex: String = ClockColorHex.defaultWakeBackground
    ) {
        self.fontID = fontID
        self.colorHex = ClockColorHex.normalized(colorHex, fallback: ClockColorHex.defaultText)
        self.size = Self.clamp(size, min: 72, max: 220)
        self.luminosity = Self.clamp(luminosity, min: 0.04, max: 1)
        self.wakeBackgroundColorHex = ClockColorHex.normalized(
            wakeBackgroundColorHex,
            fallback: ClockColorHex.defaultWakeBackground
        )
    }

    public static let `default` = ClockFaceSettings(
        fontID: .rounded,
        colorHex: ClockColorHex.defaultText,
        size: 132,
        luminosity: 0.42,
        wakeBackgroundColorHex: ClockColorHex.defaultWakeBackground
    )

    private enum CodingKeys: String, CodingKey {
        case fontID
        case colorHex
        case size
        case luminosity
        case wakeBackgroundColorHex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fontRawValue = try container.decodeIfPresent(String.self, forKey: .fontID)
        let fontID = fontRawValue.flatMap(ClockFontID.init(rawValue:)) ?? .rounded
        let colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? ClockColorHex.defaultText
        let size = try container.decodeIfPresent(Double.self, forKey: .size) ?? Self.default.size
        let luminosity = try container.decodeIfPresent(Double.self, forKey: .luminosity) ?? Self.default.luminosity
        let wakeBackgroundColorHex = try container.decodeIfPresent(String.self, forKey: .wakeBackgroundColorHex)
            ?? ClockColorHex.defaultWakeBackground

        self.init(
            fontID: fontID,
            colorHex: colorHex,
            size: size,
            luminosity: luminosity,
            wakeBackgroundColorHex: wakeBackgroundColorHex
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fontID, forKey: .fontID)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(size, forKey: .size)
        try container.encode(luminosity, forKey: .luminosity)
        try container.encode(wakeBackgroundColorHex, forKey: .wakeBackgroundColorHex)
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(max, Swift.max(min, value))
    }
}
