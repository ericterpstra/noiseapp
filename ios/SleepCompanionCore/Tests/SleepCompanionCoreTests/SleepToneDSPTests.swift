import XCTest
@testable import SleepCompanionCore

final class SleepToneDSPTests: XCTestCase {
    func testOutputLevelMappingUsesLouderBoundedCurve() {
        XCTAssertEqual(SoundOutputMapping.mixerOutputVolume(level: -0.5), 0, accuracy: 0.0001)
        XCTAssertEqual(SoundOutputMapping.mixerOutputVolume(level: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(SoundOutputMapping.mixerOutputVolume(level: 1), 1, accuracy: 0.0001)
        XCTAssertEqual(SoundOutputMapping.mixerOutputVolume(level: 1.5), 1, accuracy: 0.0001)
        XCTAssertGreaterThan(SoundOutputMapping.mixerOutputVolume(level: 0.75), pow(0.75, 2) * 0.9)
        XCTAssertGreaterThan(SoundOutputMapping.mixerOutputVolume(level: 0.42), pow(0.42, 2) * 0.9)
    }

    func testFanAirHasNoFloorAndHumCanLeadFanBody() {
        XCTAssertEqual(SleepToneDSP.fanAirLayerLevel(0), 0, accuracy: 0.0001)
        XCTAssertEqual(SleepToneDSP.fanHumLayerLevel(0), 0, accuracy: 0.0001)
        XCTAssertLessThan(SleepToneDSP.fanAirLayerLevel(1), SleepToneDSP.fanHumLayerLevel(1))
        XCTAssertGreaterThan(SleepToneDSP.fanHumLayerLevel(1), SleepToneDSP.fanHumLayerLevel(0.25))
        XCTAssertGreaterThan(SleepToneDSP.fanRumbleLayerLevel(1), SleepToneDSP.fanRumbleLayerLevel(0.25))
    }

    func testGreenLayerCanBeDisabledOrBlended() {
        XCTAssertEqual(SleepToneDSP.greenLayerLevel(-0.5), 0)
        XCTAssertEqual(SleepToneDSP.greenLayerLevel(0), 0)
        XCTAssertGreaterThan(SleepToneDSP.greenLayerLevel(0.25), 0)
        XCTAssertGreaterThan(SleepToneDSP.greenLayerLevel(1), SleepToneDSP.greenLayerLevel(0.25))
    }

    func testRendererGeneratesFiniteStereoSamples() {
        var renderer = SleepToneDSP.ChannelRenderer(sampleRate: 48_000, seed: 1234)
        let parameters = SoundPresetDefinition.defaultPreset.parameters

        let sample = renderer.nextSample(parameters: parameters)

        XCTAssertTrue(sample.left.isFinite)
        XCTAssertTrue(sample.right.isFinite)
        XCTAssertGreaterThanOrEqual(sample.left, -1)
        XCTAssertLessThanOrEqual(sample.left, 1)
        XCTAssertGreaterThanOrEqual(sample.right, -1)
        XCTAssertLessThanOrEqual(sample.right, 1)
    }

    func testRendererIsDeterministicForTheSameSeed() {
        var first = SleepToneDSP.ChannelRenderer(sampleRate: 48_000, seed: 99)
        var second = SleepToneDSP.ChannelRenderer(sampleRate: 48_000, seed: 99)
        let parameters = SoundPresetDefinition.defaultPreset.parameters

        let firstSamples = (0..<8).map { _ in first.nextSample(parameters: parameters) }
        let secondSamples = (0..<8).map { _ in second.nextSample(parameters: parameters) }

        XCTAssertEqual(firstSamples, secondSamples)
    }
}
