import {
  FAN_AIR_BROWN_MIX,
  FAN_RUMBLE_FILTERS,
  fanAirLevel,
  fanHumFrequency,
  fanHumLevel,
  fanRumbleLevel,
} from "./tone-shaping.js";

export const DEFAULT_SLEEP_TONE_CONFIG = Object.freeze({
  fanAir: 0.55,
  fanRumble: 0.65,
  fanHum: 0.52,
  fanHumPitch: 92,
  fanDrift: 0.32,
  greenMix: 0.25,
  warmth: 0.35,
  lowCut: 0,
  highCut: 1,
  width: 1,
});

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function coefficientForCutoff(frequency, sampleRate) {
  return 1 - Math.exp((-2 * Math.PI * frequency) / sampleRate);
}

export function greenLayerLevel(greenMix) {
  const mix = clamp(greenMix, 0, 1);
  return mix <= 0 ? 0 : mix ** 1.1 * 0.34;
}

export function createSleepToneChannelState(sampleRate = 48000) {
  return {
    brown: 0,
    previousWhite: 0,
    pinkB0: 0,
    pinkB1: 0,
    pinkB2: 0,
    pinkB3: 0,
    pinkB4: 0,
    pinkB5: 0,
    pinkB6: 0,
    air1: 0,
    air2: 0,
    rumble1: 0,
    rumble2: 0,
    greenLow: 0,
    greenFloor: 0,
    humPhase: Math.random() * Math.PI * 2,
    motionPhase: Math.random() * Math.PI * 2,
    flutterPhase: Math.random() * Math.PI * 2,
    drift: 0,
    driftTarget: 0,
    driftCounter: Math.floor(sampleRate * (0.35 + Math.random() * 0.4)),
    phaseOffset: Math.random() * Math.PI * 2,
    coefficientsReady: false,
    airCoeff1: 0,
    airCoeff2: 0,
    rumbleCoeff1: 0,
    rumbleCoeff2: 0,
    greenLowCoeff: 0,
    greenFloorCoeff: 0,
    sampleRate: 0,
  };
}

function ensureStateCoefficients(state, sampleRate) {
  if (state.coefficientsReady && state.sampleRate === sampleRate) {
    return;
  }

  state.sampleRate = sampleRate;
  state.airCoeff1 = coefficientForCutoff(700, sampleRate);
  state.airCoeff2 = coefficientForCutoff(420, sampleRate);
  state.rumbleCoeff1 = coefficientForCutoff(FAN_RUMBLE_FILTERS.firstCutoff, sampleRate);
  state.rumbleCoeff2 = coefficientForCutoff(FAN_RUMBLE_FILTERS.secondCutoff, sampleRate);
  state.greenLowCoeff = coefficientForCutoff(1800, sampleRate);
  state.greenFloorCoeff = coefficientForCutoff(220, sampleRate);
  state.coefficientsReady = true;
}

export function generatePinkSample(state, white) {
  state.pinkB0 = 0.99886 * state.pinkB0 + white * 0.0555179;
  state.pinkB1 = 0.99332 * state.pinkB1 + white * 0.0750759;
  state.pinkB2 = 0.969 * state.pinkB2 + white * 0.153852;
  state.pinkB3 = 0.8665 * state.pinkB3 + white * 0.3104856;
  state.pinkB4 = 0.55 * state.pinkB4 + white * 0.5329522;
  state.pinkB5 = -0.7616 * state.pinkB5 - white * 0.016898;

  const pink =
    state.pinkB0 +
    state.pinkB1 +
    state.pinkB2 +
    state.pinkB3 +
    state.pinkB4 +
    state.pinkB5 +
    state.pinkB6 +
    white * 0.5362;

  state.pinkB6 = white * 0.115926;

  return pink * 0.11;
}

export function generateBrownSample(state, white) {
  const brown = (state.brown + 0.02 * white) / 1.02;
  state.brown = brown;
  return brown * 3.5;
}

function generateGreenBandSample(state, white) {
  state.greenLow += state.greenLowCoeff * (white - state.greenLow);
  state.greenFloor += state.greenFloorCoeff * (white - state.greenFloor);
  return (state.greenLow - state.greenFloor) * 0.86;
}

export function generateSleepToneSample(state, white, config = DEFAULT_SLEEP_TONE_CONFIG, sampleRate = 48000) {
  ensureStateCoefficients(state, sampleRate);

  const pink = generatePinkSample(state, white);
  const brown = generateBrownSample(state, white);
  const fanAir = clamp(config.fanAir ?? DEFAULT_SLEEP_TONE_CONFIG.fanAir, 0, 1);
  const fanRumble = clamp(config.fanRumble ?? DEFAULT_SLEEP_TONE_CONFIG.fanRumble, 0, 1);
  const fanHum = clamp(config.fanHum ?? DEFAULT_SLEEP_TONE_CONFIG.fanHum, 0, 1);
  const fanHumPitch = config.fanHumPitch ?? DEFAULT_SLEEP_TONE_CONFIG.fanHumPitch;
  const fanDrift = clamp(config.fanDrift ?? DEFAULT_SLEEP_TONE_CONFIG.fanDrift, 0, 1);
  const warmth = clamp(config.warmth ?? DEFAULT_SLEEP_TONE_CONFIG.warmth, 0, 1);
  const greenLevel = greenLayerLevel(config.greenMix ?? DEFAULT_SLEEP_TONE_CONFIG.greenMix);

  const airSource = pink * (1 - FAN_AIR_BROWN_MIX) + brown * FAN_AIR_BROWN_MIX;
  state.air1 += state.airCoeff1 * (airSource - state.air1);
  state.air2 += state.airCoeff2 * (state.air1 - state.air2);
  const air = state.air2;

  const rumbleSource = brown * 0.9 + pink * 0.1;
  state.rumble1 += state.rumbleCoeff1 * (rumbleSource - state.rumble1);
  state.rumble2 += state.rumbleCoeff2 * (state.rumble1 - state.rumble2);
  const rumble = state.rumble2;

  state.driftCounter -= 1;
  if (state.driftCounter <= 0) {
    state.driftCounter = Math.floor(sampleRate * (0.35 + Math.random() * 0.65));
    state.driftTarget = Math.random() * 2 - 1;
  }

  state.drift += 0.00005 * (state.driftTarget - state.drift);
  state.motionPhase += (2 * Math.PI * (0.07 + fanDrift * 0.05)) / sampleRate;
  state.flutterPhase += (2 * Math.PI * (0.17 + fanDrift * 0.11)) / sampleRate;

  if (state.motionPhase > Math.PI * 2) {
    state.motionPhase -= Math.PI * 2;
  }

  if (state.flutterPhase > Math.PI * 2) {
    state.flutterPhase -= Math.PI * 2;
  }

  const motion =
    Math.sin(state.motionPhase + state.phaseOffset) * 0.6 +
    Math.sin(state.flutterPhase * 1.9 + state.phaseOffset * 0.37) * 0.4;
  const humFrequency = fanHumFrequency({
    fanHumPitch,
    fanDrift,
    drift: state.drift,
    motion,
  });

  state.humPhase += (2 * Math.PI * humFrequency) / sampleRate;
  if (state.humPhase > Math.PI * 2) {
    state.humPhase -= Math.PI * 2;
  }

  const humWave =
    Math.sin(state.humPhase) * 0.74 +
    Math.sin(state.humPhase * 2.01 + 0.4) * 0.18 +
    Math.sin(state.humPhase * 3.97 + 1.1) * 0.05;
  const bedMotion = 1 + fanDrift * (state.drift * 0.09 + motion * 0.06);
  const airLevel = fanAirLevel(fanAir) * (1 - warmth * 0.12);
  const rumbleLevel = fanRumbleLevel(fanRumble) * (1 + warmth * 0.08);
  const humLevel = fanHumLevel(fanHum);
  const fanBed = (air * airLevel + rumble * rumbleLevel) * bedMotion + humWave * humLevel;

  if (greenLevel <= 0) {
    return fanBed;
  }

  return fanBed + generateGreenBandSample(state, white) * greenLevel;
}
