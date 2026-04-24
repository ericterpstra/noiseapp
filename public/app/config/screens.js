function freezeScreen(screen) {
  return Object.freeze({
    ...screen,
    regions: Object.freeze({
      controls: Object.freeze({
        ...screen.regions.controls,
        controls: Object.freeze([...screen.regions.controls.controls]),
      }),
    }),
  });
}

export const DEFAULT_SCREEN_ID = "generator";

export const SCREEN_DEFINITIONS = Object.freeze(
  [
    {
      id: "generator",
      regions: {
        controls: {
          selector: "#toneControls",
          controls: [
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
          ],
        },
      },
    },
  ].map(freezeScreen),
);

export const SCREEN_BY_ID = Object.freeze(
  Object.fromEntries(SCREEN_DEFINITIONS.map((screen) => [screen.id, screen])),
);

export function getScreenDefinition(screenId = DEFAULT_SCREEN_ID) {
  const screen = SCREEN_BY_ID[screenId];

  if (!screen) {
    throw new Error(`Unknown screen: ${screenId}`);
  }

  return screen;
}
