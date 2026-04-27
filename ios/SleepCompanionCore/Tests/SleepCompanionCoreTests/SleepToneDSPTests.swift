import XCTest
@testable import SleepCompanionCore

final class SleepToneDSPTests: XCTestCase {
    func testOutputLevelMappingUsesLouderBoundedCurve() {
        XCTAssertEqual(SoundOutputMapping.mixerOutputVolume(level: -0.5), 0, accuracy: 0.0001)
        XCTAssertEqual(SoundOutputMapping.mixerOutputVolume(level: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(SoundOutputMapping.mixerOutputVolume(level: 1), 1, accuracy: 0.0001)
        XCTAssertEqual(SoundOutputMapping.mixerOutputVolume(level: 1.5), 1, accuracy: 0.0001)
        XCTAssertEqual(SoundOutputMapping.renderDrive(level: -0.5), 1, accuracy: 0.0001)
        XCTAssertEqual(SoundOutputMapping.renderDrive(level: 1.5), SoundOutputMapping.renderDrive(level: 1), accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(SoundOutputMapping.renderDrive(level: 1), 2)
        XCTAssertGreaterThan(SoundOutputMapping.mixerOutputVolume(level: 0.75), pow(0.75, 2) * 0.9)
        XCTAssertGreaterThan(SoundOutputMapping.mixerOutputVolume(level: 0.42), pow(0.42, 2) * 0.9)
    }

    func testFanAirHasNoFloorAndHumCanLeadFanBody() {
        XCTAssertEqual(SleepToneDSP.fanAirLayerLevel(0), 0, accuracy: 0.0001)
        XCTAssertEqual(SleepToneDSP.fanHumLayerLevel(0), 0, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(SleepToneDSP.fanAirLayerLevel(1), 0.5)
        XCTAssertGreaterThanOrEqual(SleepToneDSP.fanHumLayerLevel(1), 1)
        XCTAssertLessThan(SleepToneDSP.fanAirLayerLevel(1), SleepToneDSP.fanHumLayerLevel(1))
        XCTAssertGreaterThan(SleepToneDSP.fanHumLayerLevel(1), SleepToneDSP.fanHumLayerLevel(0.25))
        XCTAssertGreaterThan(SleepToneDSP.fanRumbleLayerLevel(1), SleepToneDSP.fanRumbleLayerLevel(0.25))
        XCTAssertGreaterThan(
            SleepToneDSP.fanHumLayerLevel(1),
            SleepToneDSP.fanRumbleLayerLevel(SoundPresetDefinition.defaultPreset.parameters.fanRumble)
        )
        XCTAssertGreaterThanOrEqual(SleepToneDSP.fanHumLayerLevel(0.52), 0.4)
    }

    func testRendererUsesOutputLevelAsSourceDrive() {
        var mediumRenderer = SleepToneDSP.ChannelRenderer(sampleRate: 48_000, seed: 8675309)
        var fullRenderer = SleepToneDSP.ChannelRenderer(sampleRate: 48_000, seed: 8675309)
        var mediumParameters = SoundPresetDefinition.defaultPreset.parameters
        var fullParameters = SoundPresetDefinition.defaultPreset.parameters
        mediumParameters.level = 0.5
        fullParameters.level = 1

        let mediumRMS = stereoRMS(renderer: &mediumRenderer, parameters: mediumParameters)
        let fullRMS = stereoRMS(renderer: &fullRenderer, parameters: fullParameters)

        XCTAssertGreaterThan(fullRMS, mediumRMS * 1.3)
    }

    func testGreenLayerCanBeDisabledOrBlended() {
        XCTAssertEqual(SleepToneDSP.greenLayerLevel(-0.5), 0)
        XCTAssertEqual(SleepToneDSP.greenLayerLevel(0), 0)
        XCTAssertGreaterThan(SleepToneDSP.greenLayerLevel(0.25), 0)
        XCTAssertGreaterThan(SleepToneDSP.greenLayerLevel(1), SleepToneDSP.greenLayerLevel(0.25))
        XCTAssertLessThanOrEqual(SleepToneDSP.greenLayerLevel(0.05), 0.002)
        XCTAssertLessThanOrEqual(SleepToneDSP.greenLayerLevel(0.25), 0.03)
        XCTAssertLessThanOrEqual(SleepToneDSP.greenLayerLevel(1), 0.14)
    }

    func testGreenLayerIsSubtleComparedWithAirflowAndHum() {
        var primaryRenderer = SleepToneDSP.ChannelRenderer(sampleRate: 48_000, seed: 4242)
        var greenRenderer = SleepToneDSP.ChannelRenderer(sampleRate: 48_000, seed: 4242)
        var primary = SoundPresetDefinition.defaultPreset.parameters
        primary.level = 1
        primary.greenMix = 0
        primary.fanAir = 0.72
        primary.fanRumble = 0.18
        primary.fanHum = 0.72

        var greenOnly = primary
        greenOnly.greenMix = 0.05
        greenOnly.fanAir = 0
        greenOnly.fanRumble = 0
        greenOnly.fanHum = 0

        let primaryRMS = stereoRMS(renderer: &primaryRenderer, parameters: primary)
        let greenRMS = stereoRMS(renderer: &greenRenderer, parameters: greenOnly)

        XCTAssertGreaterThan(primaryRMS, greenRMS * 5)
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

    private func stereoRMS(
        renderer: inout SleepToneDSP.ChannelRenderer,
        parameters: SoundParameters,
        sampleCount: Int = 4_096
    ) -> Double {
        var sumOfSquares = 0.0

        for _ in 0..<sampleCount {
            let sample = renderer.nextSample(parameters: parameters)
            sumOfSquares += sample.left * sample.left
            sumOfSquares += sample.right * sample.right
        }

        return sqrt(sumOfSquares / Double(sampleCount * 2))
    }
}
