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
    level: 42,
    greenMix: 25,
    width: 100,
    warmth: 35,
    lowCut: 0,
    highCut: 100,
    fanAir: 55,
    fanRumble: 65,
    fanHum: 52,
    fanHumPitch: 92,
    fanDrift: 32,
  });

  assert.equal(getControlDefinition("greenMix").formatValue(0), "Off");
  assert.equal(getControlDefinition("greenMix").formatValue(25), "25%");
  assert.equal(getControlDefinition("warmth").formatValue(35), "35%");
  assert.equal(getControlDefinition("fanHumPitch").formatValue(45), "45 Hz");
  assert.equal(getControlDefinition("lowCut").formatValue(0), "20 Hz");
  assert.equal(getControlDefinition("highCut").formatValue(100), "20 kHz");
});

test("source registry centralizes copy, routing, and source-specific controls", () => {
  assert.equal(DEFAULT_SOURCE_ID, "sleepTone");
  assert.equal(SOURCE_DEFINITIONS.length, 1);
  assert.equal(getSourceDefinition("missing").id, "sleepTone");
  assert.deepEqual(getSourceDefinition("sleepTone").controls, [
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

  const controlIds = new Set(CONTROL_DEFINITIONS.map((control) => control.id));

  for (const source of SOURCE_DEFINITIONS) {
    assert.ok(source.id);
    assert.ok(source.title);
    assert.ok(source.description);
    assert.ok(source.detail);
    assert.equal(source.generatorMode, "sleepTone");
    assert.equal(source.route, "direct");

    for (const controlId of source.controls) {
      assert.ok(controlIds.has(controlId), `${source.id} references unknown control ${controlId}`);
    }
  }
});

test("screen definitions reference known controls and mounting regions", () => {
  const controlIds = new Set(CONTROL_DEFINITIONS.map((control) => control.id));

  for (const screen of SCREEN_DEFINITIONS) {
    assert.ok(screen.id);
    assert.deepEqual(Object.keys(screen.regions), ["controls"]);
    assert.ok(screen.regions.controls.selector);

    for (const controlId of screen.regions.controls.controls) {
      assert.ok(controlIds.has(controlId), `${screen.id} references unknown control ${controlId}`);
    }
  }
});
