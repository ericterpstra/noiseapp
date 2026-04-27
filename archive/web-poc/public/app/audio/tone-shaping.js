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
