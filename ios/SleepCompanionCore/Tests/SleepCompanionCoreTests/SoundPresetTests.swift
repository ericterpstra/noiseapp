import XCTest
@testable import SleepCompanionCore

final class SoundPresetTests: XCTestCase {
    func testBundledPresetsAreProceduralDefinitions() {
        let presets = SoundPresetDefinition.bundledPresets

        XCTAssertEqual(presets.map(\.id), ["deep-fan", "soft-green", "low-rumble"])
        XCTAssertTrue(presets.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(presets.allSatisfy { !$0.description.isEmpty })
        XCTAssertTrue(presets.allSatisfy { $0.audioAssetName == nil })
    }

    func testDefaultPresetMatchesWebProofOfConceptDefaults() {
        let preset = SoundPresetDefinition.defaultPreset

        XCTAssertEqual(preset.id, "deep-fan")
        XCTAssertEqual(preset.parameters.level, 0.42, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.greenMix, 0.25, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanAir, 0.55, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanRumble, 0.65, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanHum, 0.52, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanHumPitch, 92, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanDrift, 0.32, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.warmth, 0.35, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.lowCut, 0, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.highCut, 1, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.width, 1, accuracy: 0.0001)
    }

    func testParametersClampToSupportedRanges() {
        let parameters = SoundParameters(
            level: 3,
            greenMix: -1,
            fanAir: 4,
            fanRumble: -0.5,
            fanHum: 2,
            fanHumPitch: 400,
            fanDrift: -2,
            warmth: 7,
            lowCut: -0.2,
            highCut: 2,
            width: 4
        ).clamped()

        XCTAssertEqual(parameters.level, 1)
        XCTAssertEqual(parameters.greenMix, 0)
        XCTAssertEqual(parameters.fanAir, 1)
        XCTAssertEqual(parameters.fanRumble, 0)
        XCTAssertEqual(parameters.fanHum, 1)
        XCTAssertEqual(parameters.fanHumPitch, 130)
        XCTAssertEqual(parameters.fanDrift, 0)
        XCTAssertEqual(parameters.warmth, 1)
        XCTAssertEqual(parameters.lowCut, 0)
        XCTAssertEqual(parameters.highCut, 1)
        XCTAssertEqual(parameters.width, 2)
    }
}
