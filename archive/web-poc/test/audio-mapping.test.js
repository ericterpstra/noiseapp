import assert from "node:assert/strict";
import { test } from "node:test";

import {
  FAN_RUMBLE_FILTERS,
  fanHumFrequency,
  fanRumbleLevel,
} from "../public/app/audio/tone-shaping.js";
import {
  DEFAULT_SLEEP_TONE_CONFIG,
  createSleepToneChannelState,
  generateSleepToneSample,
  greenLayerLevel,
} from "../public/app/audio/sleep-tone-dsp.js";

test("fan hum pitch can be lowered below the original fixed hum", () => {
  assert.equal(DEFAULT_SLEEP_TONE_CONFIG.fanHumPitch, 92);
  assert.equal(fanHumFrequency({ fanHumPitch: 45, fanDrift: 0, drift: 0, motion: 0 }), 45);
});

test("fan rumble has a wider audible range", () => {
  assert.equal(fanRumbleLevel(0), 0);
  assert.ok(fanRumbleLevel(1) >= 0.95);
  assert.ok(FAN_RUMBLE_FILTERS.firstCutoff > 70);
  assert.ok(FAN_RUMBLE_FILTERS.secondCutoff > 32);
});

test("green layer can be fully disabled or blended into the sleep tone", () => {
  assert.equal(greenLayerLevel(0), 0);
  assert.equal(greenLayerLevel(-0.25), 0);
  assert.ok(greenLayerLevel(0.25) > 0);
  assert.ok(greenLayerLevel(1) > greenLayerLevel(0.25));
});

test("shared sleep tone DSP generates finite samples for fallback and worklet use", () => {
  const state = createSleepToneChannelState(48000);
  const sample = generateSleepToneSample(state, 0.42, DEFAULT_SLEEP_TONE_CONFIG, 48000);

  assert.equal(Number.isFinite(sample), true);
});
