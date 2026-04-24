import SwiftUI

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
}

struct ClockColorChoice {
    var name: String
    var hex: String

    static let all: [ClockColorChoice] = [
        ClockColorChoice(name: "Warm White", hex: "#F8F2E7"),
        ClockColorChoice(name: "Soft Amber", hex: "#E0B86E"),
        ClockColorChoice(name: "Seafoam", hex: "#8FD6C7"),
        ClockColorChoice(name: "Sky", hex: "#78DCE8"),
        ClockColorChoice(name: "Rose", hex: "#F4A6B8")
    ]
}
