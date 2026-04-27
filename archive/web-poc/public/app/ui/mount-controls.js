import { getControlDefinition } from "../config/controls.js";

function appendRangeControl(document, label, control) {
  const labelRow = document.createElement("div");
  labelRow.className = "control-label";

  const labelText = document.createElement("span");
  labelText.textContent = control.label;

  const output = document.createElement("output");
  output.id = `${control.id}Value`;
  output.setAttribute("for", control.id);
  output.textContent = control.formatValue(control.defaultValue);

  const input = document.createElement("input");
  input.id = control.id;
  input.type = "range";
  input.min = String(control.min);
  input.max = String(control.max);
  input.step = String(control.step);
  input.value = String(control.defaultValue);

  labelRow.append(labelText, output);
  label.append(labelRow, input);

  return { input, output };
}

function createControlElement(document, control) {
  const label = document.createElement("label");
  label.className = "control";

  const refs = appendRangeControl(document, label, control);

  return {
    element: label,
    refs,
  };
}

function mountControl(document, container, controls, controlId) {
  const control = getControlDefinition(controlId);
  const { element, refs } = createControlElement(document, control);

  container.append(element);
  controls[control.id] = refs.input;
  controls[`${control.id}Value`] = refs.output;
}

export function mountScreenControls(document, screen) {
  const controls = {};
  const controlsRegion = document.querySelector(screen.regions.controls.selector);

  if (controlsRegion) {
    controlsRegion.replaceChildren();

    for (const controlId of screen.regions.controls.controls) {
      mountControl(document, controlsRegion, controls, controlId);
    }
  }

  return controls;
}
