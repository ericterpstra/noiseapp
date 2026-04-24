import {
  formatHighCut,
  formatLowCut,
  formatFrequency,
  formatOptionalPercent,
  formatPercent,
} from "../ui/formatters.js";

const numberParser = (value) => Number(value);

function freezeControl(control) {
  return Object.freeze(control);
}

export const CONTROL_DEFINITIONS = Object.freeze(
  [
    {
      id: "level",
      label: "Output Level",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 42,
      parse: numberParser,
      formatValue: formatPercent,
    },
    {
      id: "greenMix",
      label: "Green Layer",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 25,
      parse: numberParser,
      formatValue: formatOptionalPercent,
    },
    {
      id: "fanAir",
      label: "Airflow",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 55,
      parse: numberParser,
      formatValue: formatPercent,
    },
    {
      id: "fanRumble",
      label: "Rumble",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 65,
      parse: numberParser,
      formatValue: formatPercent,
    },
    {
      id: "fanHum",
      label: "Hum",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 52,
      parse: numberParser,
      formatValue: formatPercent,
    },
    {
      id: "fanHumPitch",
      label: "Hum Pitch",
      input: "range",
      min: 40,
      max: 130,
      step: 1,
      defaultValue: 92,
      parse: numberParser,
      formatValue: formatFrequency,
    },
    {
      id: "fanDrift",
      label: "Movement",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 32,
      parse: numberParser,
      formatValue: formatPercent,
    },
    {
      id: "warmth",
      label: "Warmth",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 35,
      parse: numberParser,
      formatValue: formatPercent,
    },
    {
      id: "lowCut",
      label: "Low Cut",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 0,
      parse: numberParser,
      formatValue: formatLowCut,
    },
    {
      id: "highCut",
      label: "High Cut",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 100,
      parse: numberParser,
      formatValue: formatHighCut,
    },
    {
      id: "width",
      label: "Stereo Width",
      input: "range",
      min: 0,
      max: 200,
      step: 1,
      defaultValue: 100,
      parse: numberParser,
      formatValue: formatPercent,
    },
  ].map(freezeControl),
);

export const CONTROL_BY_ID = Object.freeze(
  Object.fromEntries(CONTROL_DEFINITIONS.map((control) => [control.id, control])),
);

export function getControlDefinition(controlId) {
  const control = CONTROL_BY_ID[controlId];

  if (!control) {
    throw new Error(`Unknown control: ${controlId}`);
  }

  return control;
}

export function getControlDefinitions(controlIds) {
  return controlIds.map((controlId) => getControlDefinition(controlId));
}

export function createDefaultState() {
  return Object.fromEntries(CONTROL_DEFINITIONS.map((control) => [control.id, control.defaultValue]));
}

export function parseControlValue(control, value) {
  return control.parse(value);
}
