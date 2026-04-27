import { CONTROL_DEFINITIONS, createDefaultState } from "../config/controls.js";

export const PRESET_KIND = "sleep-tone-preset";
export const PRESET_VERSION = 1;

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function normalizeControlValue(control, value) {
  const fallback = control.defaultValue;
  const numericValue = Number(value);

  if (!Number.isFinite(numericValue)) {
    return fallback;
  }

  return clamp(numericValue, control.min, control.max);
}

function normalizeValues(values = {}) {
  return Object.fromEntries(
    CONTROL_DEFINITIONS.map((control) => [
      control.id,
      normalizeControlValue(control, Object.hasOwn(values, control.id) ? values[control.id] : control.defaultValue),
    ]),
  );
}

export function createPresetPayload(state) {
  return {
    kind: PRESET_KIND,
    version: PRESET_VERSION,
    values: normalizeValues(state),
  };
}

export function readPresetPayload(payload) {
  if (
    !payload ||
    payload.kind !== PRESET_KIND ||
    payload.version !== PRESET_VERSION ||
    typeof payload.values !== "object" ||
    payload.values === null
  ) {
    return null;
  }

  return {
    ...createDefaultState(),
    ...normalizeValues(payload.values),
  };
}
