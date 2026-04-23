import { getControlDefinition } from "../config/controls.js";
import { SOURCE_DEFINITIONS, getSourceOptions } from "../config/sources.js";

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

function appendSelectControl(document, label, control) {
  const labelText = document.createElement("span");
  labelText.textContent = control.label;

  const select = document.createElement("select");
  select.id = control.id;

  const options = control.options === "sources" ? getSourceOptions() : control.options;

  for (const optionConfig of options) {
    const option = document.createElement("option");
    option.value = optionConfig.value;
    option.textContent = optionConfig.label;
    select.append(option);
  }

  select.value = String(control.defaultValue);
  label.append(labelText, select);

  return { input: select, output: null };
}

function createControlElement(document, control) {
  const label = document.createElement("label");
  label.className = control.input === "select" ? "control control-select" : "control";

  const refs =
    control.input === "select"
      ? appendSelectControl(document, label, control)
      : appendRangeControl(document, label, control);

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

  if (refs.output) {
    controls[`${control.id}Value`] = refs.output;
  }
}

export function mountScreenControls(document, screen) {
  const controls = {};
  const coreRegion = document.querySelector(screen.regions.coreControls.selector);

  if (coreRegion) {
    coreRegion.replaceChildren();

    for (const controlId of screen.regions.coreControls.controls) {
      mountControl(document, coreRegion, controls, controlId);
    }
  }

  const sourceRegion = document.querySelector(screen.regions.sourceControls.selector);

  if (sourceRegion) {
    sourceRegion.replaceChildren();

    for (const source of SOURCE_DEFINITIONS) {
      if (source.controls.length === 0) {
        continue;
      }

      const group = document.createElement("div");
      group.id = `${source.id}Controls`;
      group.className = "detail-group";
      group.hidden = true;
      group.dataset.sourceControls = source.id;

      for (const controlId of source.controls) {
        mountControl(document, group, controls, controlId);
      }

      sourceRegion.append(group);
      controls[group.id] = group;
    }
  }

  return controls;
}
