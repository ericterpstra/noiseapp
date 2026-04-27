import assert from "node:assert/strict";
import { test } from "node:test";

import { createDefaultState } from "../public/app/config/controls.js";
import {
  PRESET_KIND,
  PRESET_VERSION,
  createPresetPayload,
  readPresetPayload,
} from "../public/app/state/presets.js";

test("preset payload serializes only known sleep tone controls", () => {
  const payload = createPresetPayload({
    ...createDefaultState(),
    greenMix: 0,
    highCut: 36,
    noiseType: "pink",
    unknown: 123,
  });

  assert.equal(payload.kind, PRESET_KIND);
  assert.equal(payload.version, PRESET_VERSION);
  assert.deepEqual(Object.keys(payload.values), [
    "level",
    "greenMix",
    "fanAir",
    "fanRumble",
    "fanHum",
    "fanHumPitch",
    "fanDrift",
    "warmth",
    "lowCut",
    "highCut",
    "width",
  ]);
  assert.equal(payload.values.greenMix, 0);
  assert.equal(payload.values.highCut, 36);
  assert.equal(payload.values.noiseType, undefined);
  assert.equal(payload.values.unknown, undefined);
});

test("preset reader defaults missing values and clamps invalid numeric values", () => {
  const state = readPresetPayload({
    kind: PRESET_KIND,
    version: PRESET_VERSION,
    values: {
      level: 120,
      greenMix: -12,
      highCut: 45,
      fanHumPitch: "not a number",
      unknown: 99,
    },
  });

  assert.deepEqual(state, {
    ...createDefaultState(),
    level: 100,
    greenMix: 0,
    highCut: 45,
    fanHumPitch: 92,
  });
});

test("preset reader rejects unrelated payloads", () => {
  assert.equal(readPresetPayload(null), null);
  assert.equal(readPresetPayload({ kind: "other", version: PRESET_VERSION, values: {} }), null);
  assert.equal(readPresetPayload({ kind: PRESET_KIND, version: 999, values: {} }), null);
});
