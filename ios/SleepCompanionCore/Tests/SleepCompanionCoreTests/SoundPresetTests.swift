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
        XCTAssertEqual(preset.parameters.drive, 0.42, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.greenMix, 0.25, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.greenColor, 0.5, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanAir, 0.55, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.airTexture, 0.08, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.airColor, 0.5, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanRumble, 0.65, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.rumbleColor, 0.5, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanHum, 0.52, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanHumPitch, 92, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.humHarmonics, 0.5, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.fanDrift, 0.32, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.movementSpeed, 0.5, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.warmth, 0.35, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.bassBoost, 0.35, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.trebleDamping, 0.35, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.lowCut, 0, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.highCut, 1, accuracy: 0.0001)
        XCTAssertEqual(preset.parameters.width, 1, accuracy: 0.0001)
    }

    func testParametersClampToSupportedRanges() {
        let parameters = SoundParameters(
            level: 3,
            drive: 4,
            greenMix: -1,
            greenColor: 3,
            fanAir: 4,
            airTexture: 2,
            airColor: -4,
            fanRumble: -0.5,
            rumbleColor: 4,
            fanHum: 2,
            fanHumPitch: 400,
            humHarmonics: -2,
            fanDrift: -2,
            movementSpeed: 4,
            warmth: 7,
            bassBoost: -1,
            trebleDamping: 9,
            lowCut: -0.2,
            highCut: 2,
            width: 4
        ).clamped()

        XCTAssertEqual(parameters.level, 1)
        XCTAssertEqual(parameters.drive, 1)
        XCTAssertEqual(parameters.greenMix, 0)
        XCTAssertEqual(parameters.greenColor, 1)
        XCTAssertEqual(parameters.fanAir, 1)
        XCTAssertEqual(parameters.airTexture, 0.35)
        XCTAssertEqual(parameters.airColor, 0)
        XCTAssertEqual(parameters.fanRumble, 0)
        XCTAssertEqual(parameters.rumbleColor, 1)
        XCTAssertEqual(parameters.fanHum, 1)
        XCTAssertEqual(parameters.fanHumPitch, 130)
        XCTAssertEqual(parameters.humHarmonics, 0)
        XCTAssertEqual(parameters.fanDrift, 0)
        XCTAssertEqual(parameters.movementSpeed, 1)
        XCTAssertEqual(parameters.warmth, 1)
        XCTAssertEqual(parameters.bassBoost, 0)
        XCTAssertEqual(parameters.trebleDamping, 1)
        XCTAssertEqual(parameters.lowCut, 0)
        XCTAssertEqual(parameters.highCut, 1)
        XCTAssertEqual(parameters.width, 2)
    }
}
