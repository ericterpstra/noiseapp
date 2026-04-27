import Foundation
import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let normalized = ClockColorHex.normalized(hex, fallback: ClockColorHex.defaultWakeBackground)
        let sanitized = normalized.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double

        switch sanitized.count {
        case 6:
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
        default:
            red = 1
            green = 1
            blue = 1
        }

        self.init(red: red, green: green, blue: blue)
    }

    func hexString(fallback: String) -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return fallback
        }

        return String(
            format: "#%02X%02X%02X",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }
}

struct ClockColorChoice {
    var name: String
    var hex: String

    static let all: [ClockColorChoice] = [
        ClockColorChoice(name: "Warm White", hex: "#F8F2E7"),
        ClockColorChoice(name: "Moon", hex: "#D9E2EC"),
        ClockColorChoice(name: "Soft Amber", hex: "#E0B86E"),
        ClockColorChoice(name: "Gold", hex: "#F2C14E"),
        ClockColorChoice(name: "Seafoam", hex: "#8FD6C7"),
        ClockColorChoice(name: "Mint", hex: "#A8E6CF"),
        ClockColorChoice(name: "Sky", hex: "#78DCE8"),
        ClockColorChoice(name: "Blue", hex: "#8CC8FF"),
        ClockColorChoice(name: "Lavender", hex: "#B8A1FF"),
        ClockColorChoice(name: "Rose", hex: "#F4A6B8"),
        ClockColorChoice(name: "Coral", hex: "#FF8A80"),
        ClockColorChoice(name: "Red", hex: "#FF5C70"),
        ClockColorChoice(name: "White", hex: "#FFFFFF"),
        ClockColorChoice(name: "Graphite", hex: "#2B3036"),
        ClockColorChoice(name: "Navy", hex: "#101A2C"),
        ClockColorChoice(name: "Black", hex: "#000000")
    ]
}
