import Foundation

public enum SleepToneDSP {
    public struct StereoSample: Equatable, Sendable {
        public var left: Double
        public var right: Double

        public init(left: Double, right: Double) {
            self.left = left
            self.right = right
        }
    }

    public struct ChannelRenderer: Sendable {
        private let sampleRate: Double
        private var random: SeededRandom
        private var leftState: ChannelState
        private var rightState: ChannelState

        public init(sampleRate: Double, seed: UInt64 = 0x5EED) {
            var random = SeededRandom(seed: seed)
            self.sampleRate = sampleRate
            self.random = random
            self.leftState = ChannelState(sampleRate: sampleRate, random: &random)
            self.rightState = ChannelState(sampleRate: sampleRate, random: &random)
        }

        public mutating func nextSample(parameters: SoundParameters) -> StereoSample {
            let parameters = parameters.clamped()
            let leftWhite = random.nextSignedUnit()
            let rightWhite = random.nextSignedUnit()
            let left = Self.clamp(
                Self.generateSample(
                    state: &leftState,
                    white: leftWhite,
                    parameters: parameters,
                    random: &random,
                    sampleRate: sampleRate
                ),
                min: -1,
                max: 1
            )
            let right = Self.clamp(
                Self.generateSample(
                    state: &rightState,
                    white: rightWhite,
                    parameters: parameters,
                    random: &random,
                    sampleRate: sampleRate
                ),
                min: -1,
                max: 1
            )

            return StereoSample(left: left, right: right)
        }

        private static func generateSample(
            state: inout ChannelState,
            white: Double,
            parameters: SoundParameters,
            random: inout SeededRandom,
            sampleRate: Double
        ) -> Double {
            let pink = generatePinkSample(state: &state, white: white)
            let brown = generateBrownSample(state: &state, white: white)
            let greenLevel = SleepToneDSP.greenLayerLevel(parameters.greenMix)

            let airSource = pink * (1 - Constants.fanAirBrownMix) + brown * Constants.fanAirBrownMix
            state.air1 += state.airCoeff1 * (airSource - state.air1)
            state.air2 += state.airCoeff2 * (state.air1 - state.air2)

            let rumbleSource = brown * 0.9 + pink * 0.1
            state.rumble1 += state.rumbleCoeff1 * (rumbleSource - state.rumble1)
            state.rumble2 += state.rumbleCoeff2 * (state.rumble1 - state.rumble2)

            state.driftCounter -= 1
            if state.driftCounter <= 0 {
                state.driftCounter = Int(sampleRate * (0.35 + random.nextUnit() * 0.65))
                state.driftTarget = random.nextSignedUnit()
            }

            state.drift += 0.00005 * (state.driftTarget - state.drift)
            state.motionPhase = wrapPhase(
                state.motionPhase + (2 * .pi * (0.07 + parameters.fanDrift * 0.05)) / sampleRate
            )
            state.flutterPhase = wrapPhase(
                state.flutterPhase + (2 * .pi * (0.17 + parameters.fanDrift * 0.11)) / sampleRate
            )

            let motion =
                sin(state.motionPhase + state.phaseOffset) * 0.6
                + sin(state.flutterPhase * 1.9 + state.phaseOffset * 0.37) * 0.4
            let humFrequency = max(
                30,
                parameters.fanHumPitch + (state.drift * 4.5 + motion * 2.2) * parameters.fanDrift
            )

            state.humPhase = wrapPhase(state.humPhase + (2 * .pi * humFrequency) / sampleRate)
            let humWave =
                sin(state.humPhase) * 0.74
                + sin(state.humPhase * 2.01 + 0.4) * 0.18
                + sin(state.humPhase * 3.97 + 1.1) * 0.05

            let bedMotion = 1 + parameters.fanDrift * (state.drift * 0.09 + motion * 0.06)
            let airLevel = SleepToneDSP.fanAirLayerLevel(parameters.fanAir) * (1 - parameters.warmth * 0.12)
            let rumbleLevel = SleepToneDSP.fanRumbleLayerLevel(parameters.fanRumble) * (1 + parameters.warmth * 0.08)
            let humLevel = SleepToneDSP.fanHumLayerLevel(parameters.fanHum)
            let fanBed = (state.air2 * airLevel + state.rumble2 * rumbleLevel) * bedMotion + humWave * humLevel

            guard greenLevel > 0 else {
                return fanBed
            }

            return fanBed + generateGreenBandSample(state: &state, white: white) * greenLevel
        }

        private static func generatePinkSample(state: inout ChannelState, white: Double) -> Double {
            state.pinkB0 = 0.99886 * state.pinkB0 + white * 0.0555179
            state.pinkB1 = 0.99332 * state.pinkB1 + white * 0.0750759
            state.pinkB2 = 0.969 * state.pinkB2 + white * 0.153852
            state.pinkB3 = 0.8665 * state.pinkB3 + white * 0.3104856
            state.pinkB4 = 0.55 * state.pinkB4 + white * 0.5329522
            state.pinkB5 = -0.7616 * state.pinkB5 - white * 0.016898

            let pink =
                state.pinkB0
                + state.pinkB1
                + state.pinkB2
                + state.pinkB3
                + state.pinkB4
                + state.pinkB5
                + state.pinkB6
                + white * 0.5362

            state.pinkB6 = white * 0.115926
            return pink * 0.11
        }

        private static func generateBrownSample(state: inout ChannelState, white: Double) -> Double {
            let brown = (state.brown + 0.02 * white) / 1.02
            state.brown = brown
            return brown * 3.5
        }

        private static func generateGreenBandSample(state: inout ChannelState, white: Double) -> Double {
            state.greenLow += state.greenLowCoeff * (white - state.greenLow)
            state.greenFloor += state.greenFloorCoeff * (white - state.greenFloor)
            return (state.greenLow - state.greenFloor) * 0.86
        }

        private static func wrapPhase(_ phase: Double) -> Double {
            phase > 2 * .pi ? phase - 2 * .pi : phase
        }

        private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
            Swift.min(max, Swift.max(min, value))
        }
    }

    public static func greenLayerLevel(_ greenMix: Double) -> Double {
        let mix = min(1, max(0, greenMix))
        return mix <= 0 ? 0 : pow(mix, 1.1) * 0.34
    }

    static func fanAirLayerLevel(_ fanAir: Double) -> Double {
        pow(clamp(fanAir), 1.05) * 0.2
    }

    static func fanRumbleLayerLevel(_ fanRumble: Double) -> Double {
        pow(clamp(fanRumble), 1.15) * 0.78
    }

    static func fanHumLayerLevel(_ fanHum: Double) -> Double {
        pow(clamp(fanHum), 0.8) * 0.36
    }

    private static func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

private enum Constants {
    static let fanAirBrownMix = 0.08
}

private struct ChannelState: Sendable {
    var brown: Double = 0
    var pinkB0: Double = 0
    var pinkB1: Double = 0
    var pinkB2: Double = 0
    var pinkB3: Double = 0
    var pinkB4: Double = 0
    var pinkB5: Double = 0
    var pinkB6: Double = 0
    var air1: Double = 0
    var air2: Double = 0
    var rumble1: Double = 0
    var rumble2: Double = 0
    var greenLow: Double = 0
    var greenFloor: Double = 0
    var humPhase: Double
    var motionPhase: Double
    var flutterPhase: Double
    var drift: Double = 0
    var driftTarget: Double = 0
    var driftCounter: Int
    var phaseOffset: Double
    var airCoeff1: Double
    var airCoeff2: Double
    var rumbleCoeff1: Double
    var rumbleCoeff2: Double
    var greenLowCoeff: Double
    var greenFloorCoeff: Double

    init(sampleRate: Double, random: inout SeededRandom) {
        humPhase = random.nextUnit() * 2 * .pi
        motionPhase = random.nextUnit() * 2 * .pi
        flutterPhase = random.nextUnit() * 2 * .pi
        driftCounter = Int(sampleRate * (0.35 + random.nextUnit() * 0.4))
        phaseOffset = random.nextUnit() * 2 * .pi
        airCoeff1 = Self.coefficient(forCutoff: 700, sampleRate: sampleRate)
        airCoeff2 = Self.coefficient(forCutoff: 420, sampleRate: sampleRate)
        rumbleCoeff1 = Self.coefficient(forCutoff: 115, sampleRate: sampleRate)
        rumbleCoeff2 = Self.coefficient(forCutoff: 48, sampleRate: sampleRate)
        greenLowCoeff = Self.coefficient(forCutoff: 1_800, sampleRate: sampleRate)
        greenFloorCoeff = Self.coefficient(forCutoff: 220, sampleRate: sampleRate)
    }

    private static func coefficient(forCutoff frequency: Double, sampleRate: Double) -> Double {
        1 - exp((-2 * .pi * frequency) / sampleRate)
    }
}

private struct SeededRandom: Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x5EED : seed
    }

    mutating func nextUnit() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let bits = state >> 11
        return Double(bits) / Double(1 << 53)
    }

    mutating func nextSignedUnit() -> Double {
        nextUnit() * 2 - 1
    }
}
