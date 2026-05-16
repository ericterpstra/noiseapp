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
            let renderDrive = SoundOutputMapping.renderDrive(drive: parameters.drive)
            let leftWhite = random.nextSignedUnit()
            let rightWhite = random.nextSignedUnit()
            let left = Self.generateSample(
                state: &leftState,
                white: leftWhite,
                parameters: parameters,
                random: &random,
                sampleRate: sampleRate
            ) * renderDrive
            let right = Self.generateSample(
                state: &rightState,
                white: rightWhite,
                parameters: parameters,
                random: &random,
                sampleRate: sampleRate
            ) * renderDrive
            let widened = Self.applyStereoWidth(left: left, right: right, width: parameters.width)

            return StereoSample(left: Self.softLimited(widened.left), right: Self.softLimited(widened.right))
        }

        private static func generateSample(
            state: inout ChannelState,
            white: Double,
            parameters: SoundParameters,
            random: inout SeededRandom,
            sampleRate: Double
        ) -> Double {
            state.updateFilterCoefficientsIfNeeded(parameters: parameters, sampleRate: sampleRate)
            let pink = generatePinkSample(state: &state, white: white)
            let brown = generateBrownSample(state: &state, white: white)
            let greenLevel = SleepToneDSP.greenLayerLevel(parameters.greenMix)

            let airSource = pink * (1 - parameters.airTexture) + brown * parameters.airTexture
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
            let movementRateScale = SoundFilterMapping.movementRateScale(speed: parameters.movementSpeed)
            state.motionPhase = wrapPhase(
                state.motionPhase + (2 * .pi * (0.07 + parameters.fanDrift * 0.05) * movementRateScale) / sampleRate
            )
            state.flutterPhase = wrapPhase(
                state.flutterPhase + (2 * .pi * (0.17 + parameters.fanDrift * 0.11) * movementRateScale) / sampleRate
            )

            let motion =
                sin(state.motionPhase + state.phaseOffset) * 0.6
                + sin(state.flutterPhase * 1.9 + state.phaseOffset * 0.37) * 0.4
            let humFrequency = max(
                30,
                parameters.fanHumPitch + (state.drift * 4.5 + motion * 2.2) * parameters.fanDrift
            )

            state.humPhase = wrapPhase(state.humPhase + (2 * .pi * humFrequency) / sampleRate)
            let harmonicScale = SoundFilterMapping.humHarmonicScale(harmonics: parameters.humHarmonics)
            let humWave =
                sin(state.humPhase) * 0.74
                + sin(state.humPhase * 2.01 + 0.4) * 0.18 * harmonicScale
                + sin(state.humPhase * 3.97 + 1.1) * 0.05 * harmonicScale

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

        private static func applyStereoWidth(left: Double, right: Double, width: Double) -> StereoSample {
            let width = min(2, max(0, width))
            let mid = (left + right) * 0.5
            let side = (left - right) * 0.5 * width
            return StereoSample(left: mid + side, right: mid - side)
        }

        private static func softLimited(_ value: Double) -> Double {
            tanh(value)
        }
    }

    public static func greenLayerLevel(_ greenMix: Double) -> Double {
        let mix = min(1, max(0, greenMix))
        return mix <= 0 ? 0 : pow(mix, 1.7) * 0.12
    }

    static func fanAirLayerLevel(_ fanAir: Double) -> Double {
        pow(clamp(fanAir), 0.95) * 0.58
    }

    static func fanRumbleLayerLevel(_ fanRumble: Double) -> Double {
        pow(clamp(fanRumble), 1.15) * 0.78
    }

    static func fanHumLayerLevel(_ fanHum: Double) -> Double {
        pow(clamp(fanHum), 0.78) * 1.15
    }

    private static func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }
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
    var airColor: Double = 0.5
    var rumbleColor: Double = 0.5
    var greenColor: Double = 0.5

    init(sampleRate: Double, random: inout SeededRandom) {
        humPhase = random.nextUnit() * 2 * .pi
        motionPhase = random.nextUnit() * 2 * .pi
        flutterPhase = random.nextUnit() * 2 * .pi
        driftCounter = Int(sampleRate * (0.35 + random.nextUnit() * 0.4))
        phaseOffset = random.nextUnit() * 2 * .pi
        let airCutoffs = SoundFilterMapping.airCutoffs(color: airColor)
        let rumbleCutoffs = SoundFilterMapping.rumbleCutoffs(color: rumbleColor)
        let greenCutoffs = SoundFilterMapping.greenBandCutoffs(color: greenColor)
        airCoeff1 = Self.coefficient(forCutoff: airCutoffs.primary, sampleRate: sampleRate)
        airCoeff2 = Self.coefficient(forCutoff: airCutoffs.secondary, sampleRate: sampleRate)
        rumbleCoeff1 = Self.coefficient(forCutoff: rumbleCutoffs.primary, sampleRate: sampleRate)
        rumbleCoeff2 = Self.coefficient(forCutoff: rumbleCutoffs.secondary, sampleRate: sampleRate)
        greenLowCoeff = Self.coefficient(forCutoff: greenCutoffs.high, sampleRate: sampleRate)
        greenFloorCoeff = Self.coefficient(forCutoff: greenCutoffs.low, sampleRate: sampleRate)
    }

    mutating func updateFilterCoefficientsIfNeeded(parameters: SoundParameters, sampleRate: Double) {
        if airColor != parameters.airColor {
            airColor = parameters.airColor
            let cutoffs = SoundFilterMapping.airCutoffs(color: airColor)
            airCoeff1 = Self.coefficient(forCutoff: cutoffs.primary, sampleRate: sampleRate)
            airCoeff2 = Self.coefficient(forCutoff: cutoffs.secondary, sampleRate: sampleRate)
        }

        if rumbleColor != parameters.rumbleColor {
            rumbleColor = parameters.rumbleColor
            let cutoffs = SoundFilterMapping.rumbleCutoffs(color: rumbleColor)
            rumbleCoeff1 = Self.coefficient(forCutoff: cutoffs.primary, sampleRate: sampleRate)
            rumbleCoeff2 = Self.coefficient(forCutoff: cutoffs.secondary, sampleRate: sampleRate)
        }

        if greenColor != parameters.greenColor {
            greenColor = parameters.greenColor
            let cutoffs = SoundFilterMapping.greenBandCutoffs(color: greenColor)
            greenLowCoeff = Self.coefficient(forCutoff: cutoffs.high, sampleRate: sampleRate)
            greenFloorCoeff = Self.coefficient(forCutoff: cutoffs.low, sampleRate: sampleRate)
        }
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
