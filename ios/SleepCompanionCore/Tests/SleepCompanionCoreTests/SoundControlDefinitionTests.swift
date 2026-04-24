import XCTest
@testable import SleepCompanionCore

final class SoundControlDefinitionTests: XCTestCase {
    func testEverySoundParameterHasExactlyOneControlDefinition() {
        let definitions = SoundControlDefinition.all

        XCTAssertEqual(definitions.map(\.id), SoundParameterID.allCases)
        XCTAssertEqual(Set(definitions.map(\.id)).count, SoundParameterID.allCases.count)
    }

    func testControlDefinitionsMatchNativeParameterRangesAndDefaults() {
        let defaultParameters = SoundPresetDefinition.defaultPreset.parameters

        for definition in SoundControlDefinition.all {
            XCTAssertEqual(definition.defaultValue, defaultParameters[definition.id], accuracy: 0.0001)
            XCTAssertGreaterThanOrEqual(definition.defaultValue, definition.minValue)
            XCTAssertLessThanOrEqual(definition.defaultValue, definition.maxValue)
            XCTAssertGreaterThan(definition.step, 0)
        }
    }

    func testControlsAreGroupedForTheLandscapeSettingsWorkspace() {
        XCTAssertEqual(SoundControlDefinition.definition(for: .level).group, .output)
        XCTAssertEqual(SoundControlDefinition.definition(for: .width).group, .output)
        XCTAssertEqual(SoundControlDefinition.definition(for: .fanAir).group, .fanBody)
        XCTAssertEqual(SoundControlDefinition.definition(for: .fanRumble).group, .fanBody)
        XCTAssertEqual(SoundControlDefinition.definition(for: .fanHum).group, .fanBody)
        XCTAssertEqual(SoundControlDefinition.definition(for: .fanHumPitch).group, .fanBody)
        XCTAssertEqual(SoundControlDefinition.definition(for: .fanDrift).group, .movement)
        XCTAssertEqual(SoundControlDefinition.definition(for: .warmth).group, .tone)
        XCTAssertEqual(SoundControlDefinition.definition(for: .lowCut).group, .tone)
        XCTAssertEqual(SoundControlDefinition.definition(for: .highCut).group, .tone)
        XCTAssertEqual(SoundControlDefinition.definition(for: .greenMix).group, .greenLayer)
    }

    func testSoundParametersCanBeReadAndWrittenByParameterID() {
        var parameters = SoundPresetDefinition.defaultPreset.parameters

        for definition in SoundControlDefinition.all {
            parameters[definition.id] = definition.maxValue + definition.step
            XCTAssertEqual(parameters[definition.id], definition.maxValue, accuracy: 0.0001)

            parameters[definition.id] = definition.minValue - definition.step
            XCTAssertEqual(parameters[definition.id], definition.minValue, accuracy: 0.0001)
        }
    }

    func testControlFormattingMatchesProofOfConceptLabels() {
        XCTAssertEqual(SoundControlDefinition.definition(for: .level).formatValue(0.42), "42%")
        XCTAssertEqual(SoundControlDefinition.definition(for: .greenMix).formatValue(0), "Off")
        XCTAssertEqual(SoundControlDefinition.definition(for: .greenMix).formatValue(0.25), "25%")
        XCTAssertEqual(SoundControlDefinition.definition(for: .fanHumPitch).formatValue(92), "92 Hz")
        XCTAssertEqual(SoundControlDefinition.definition(for: .lowCut).formatValue(0), "20 Hz")
        XCTAssertEqual(SoundControlDefinition.definition(for: .highCut).formatValue(1), "20 kHz")
        XCTAssertEqual(SoundControlDefinition.definition(for: .width).formatValue(1.25), "125%")
    }
}
