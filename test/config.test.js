import assert from "node:assert/strict";
import { test } from "node:test";

import {
  CONTROL_DEFINITIONS,
  createDefaultState,
  getControlDefinition,
} from "../public/app/config/controls.js";
import {
  DEFAULT_SOURCE_ID,
  SOURCE_DEFINITIONS,
  getSourceDefinition,
} from "../public/app/config/sources.js";
import { SCREEN_DEFINITIONS } from "../public/app/config/screens.js";

test("control schema owns defaults and formatting for current knobs", () => {
  const defaults = createDefaultState();

  assert.deepEqual(defaults, {
    noiseType: "fan",
    level: 42,
    width: 100,
    tilt: 0,
    lowCut: 0,
    highCut: 100,
    fanAir: 55,
    fanRumble: 65,
    fanHum: 52,
    fanHumPitch: 92,
    fanDrift: 32,
    greenCenter: 54,
    greenQ: 180,
    greyAmount: 100,
  });

  assert.equal(getControlDefinition("tilt").formatValue(4), "+4 dB");
  assert.equal(getControlDefinition("fanHumPitch").formatValue(45), "45 Hz");
  assert.equal(getControlDefinition("greenQ").formatValue(180), "1.8");
  assert.equal(getControlDefinition("lowCut").formatValue(0), "20 Hz");
  assert.equal(getControlDefinition("highCut").formatValue(100), "20 kHz");
});

test("source registry centralizes copy, routing, and source-specific controls", () => {
  assert.equal(DEFAULT_SOURCE_ID, "fan");
  assert.equal(getSourceDefinition("green").generatorMode, "white");
  assert.equal(getSourceDefinition("grey").route, "grey");

  const controlIds = new Set(CONTROL_DEFINITIONS.map((control) => control.id));

  for (const source of SOURCE_DEFINITIONS) {
    assert.ok(source.id);
    assert.ok(source.title);
    assert.ok(source.description);
    assert.ok(source.detail);
    assert.ok(["direct", "green", "grey"].includes(source.route));

    for (const controlId of source.controls) {
      assert.ok(controlIds.has(controlId), `${source.id} references unknown control ${controlId}`);
    }
  }
});

test("screen definitions reference known controls and mounting regions", () => {
  const controlIds = new Set(CONTROL_DEFINITIONS.map((control) => control.id));

  for (const screen of SCREEN_DEFINITIONS) {
    assert.ok(screen.id);
    assert.ok(screen.regions.coreControls.selector);
    assert.ok(screen.regions.sourceControls.selector);

    for (const controlId of screen.regions.coreControls.controls) {
      assert.ok(controlIds.has(controlId), `${screen.id} references unknown control ${controlId}`);
    }
  }
});
