import {
  formatGreenCenter,
  formatHighCut,
  formatLowCut,
  formatFrequency,
  formatPercent,
  formatQ,
  formatSignedDecibels,
} from "../ui/formatters.js";

const numberParser = (value) => Number(value);
const stringParser = (value) => value;

function freezeControl(control) {
  return Object.freeze(control);
}

export const CONTROL_DEFINITIONS = Object.freeze(
  [
    {
      id: "noiseType",
      label: "Source",
      input: "select",
      options: "sources",
      defaultValue: "fan",
      parse: stringParser,
    },
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
    {
      id: "tilt",
      label: "Brightness Tilt",
      input: "range",
      min: -12,
      max: 12,
      step: 1,
      defaultValue: 0,
      parse: numberParser,
      formatValue: formatSignedDecibels,
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
      id: "greenCenter",
      label: "Green Center",
      input: "range",
      min: 0,
      max: 100,
      step: 1,
      defaultValue: 54,
      parse: numberParser,
      formatValue: formatGreenCenter,
    },
    {
      id: "greenQ",
      label: "Green Q",
      input: "range",
      min: 30,
      max: 600,
      step: 1,
      defaultValue: 180,
      parse: numberParser,
      formatValue: formatQ,
    },
    {
      id: "greyAmount",
      label: "Contour Amount",
      input: "range",
      min: 0,
      max: 150,
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
