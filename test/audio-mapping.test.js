import assert from "node:assert/strict";
import { test } from "node:test";

import {
  DEFAULT_GENERATOR_CONFIG,
  FAN_RUMBLE_FILTERS,
  fanHumFrequency,
  fanRumbleLevel,
  greenTrimGainForQ,
} from "../public/app/audio/tone-shaping.js";

test("fan hum pitch can be lowered below the original fixed hum", () => {
  assert.equal(DEFAULT_GENERATOR_CONFIG.fanHumPitch, 92);
  assert.equal(fanHumFrequency({ fanHumPitch: 45, fanDrift: 0, drift: 0, motion: 0 }), 45);
});

test("fan rumble has a wider audible range", () => {
  assert.equal(fanRumbleLevel(0), 0);
  assert.ok(fanRumbleLevel(1) >= 0.95);
  assert.ok(FAN_RUMBLE_FILTERS.firstCutoff > 70);
  assert.ok(FAN_RUMBLE_FILTERS.secondCutoff > 32);
});

test("green bandpass trim compensates as Q narrows the band", () => {
  assert.ok(greenTrimGainForQ(6) > greenTrimGainForQ(0.3));
  assert.ok(greenTrimGainForQ(6) > 4);
});
