import Foundation

public enum FrequencyMapping {
    public static func logFrequency(value: Double, min minimum: Double, max maximum: Double) -> Double {
        let clampedValue = Swift.min(1, Swift.max(0, value))
        let minimum = Swift.max(0.0001, minimum)
        let maximum = Swift.max(minimum, maximum)
        return minimum * pow(maximum / minimum, clampedValue)
    }
}
