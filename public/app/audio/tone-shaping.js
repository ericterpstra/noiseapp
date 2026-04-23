export const DEFAULT_GENERATOR_CONFIG = Object.freeze({
  mode: "fan",
  fanAir: 0.55,
  fanRumble: 0.65,
  fanHum: 0.52,
  fanHumPitch: 92,
  fanDrift: 0.32,
});

export const FAN_RUMBLE_FILTERS = Object.freeze({
  firstCutoff: 115,
  secondCutoff: 48,
});

export const FAN_AIR_BROWN_MIX = 0.08;

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

export function fanAirLevel(fanAir) {
  return 0.12 + clamp(fanAir, 0, 1) * 0.22;
}

export function fanRumbleLevel(fanRumble) {
  return clamp(fanRumble, 0, 1) ** 1.1 * 1.05;
}

export function fanHumLevel(fanHum) {
  return 0.04 + clamp(fanHum, 0, 1) * 0.16;
}

export function fanHumFrequency({ fanHumPitch, fanDrift, drift, motion }) {
  const modulatedPitch = fanHumPitch + (drift * 4.5 + motion * 2.2) * fanDrift;
  return Math.max(30, modulatedPitch);
}

export function greenTrimGainForQ(greenQ) {
  const q = clamp(greenQ, 0.3, 6);
  return 2.8 + q * 0.38;
}
