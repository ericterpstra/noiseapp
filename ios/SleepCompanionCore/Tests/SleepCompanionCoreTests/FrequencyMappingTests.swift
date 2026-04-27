import XCTest
@testable import SleepCompanionCore

final class FrequencyMappingTests: XCTestCase {
    func testLogFrequencyMapsSliderEdgesAndMidpoint() {
        XCTAssertEqual(FrequencyMapping.logFrequency(value: 0, min: 20, max: 1_500), 20, accuracy: 0.0001)
        XCTAssertEqual(FrequencyMapping.logFrequency(value: 1, min: 20, max: 1_500), 1_500, accuracy: 0.0001)
        XCTAssertEqual(
            FrequencyMapping.logFrequency(value: 0.5, min: 20, max: 1_500),
            sqrt(20 * 1_500),
            accuracy: 0.0001
        )
    }

    func testLogFrequencyClampsInput() {
        XCTAssertEqual(FrequencyMapping.logFrequency(value: -1, min: 20, max: 1_500), 20, accuracy: 0.0001)
        XCTAssertEqual(FrequencyMapping.logFrequency(value: 2, min: 20, max: 1_500), 1_500, accuracy: 0.0001)
    }
}
