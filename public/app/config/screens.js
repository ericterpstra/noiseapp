function freezeScreen(screen) {
  return Object.freeze({
    ...screen,
    regions: Object.freeze({
      coreControls: Object.freeze({
        ...screen.regions.coreControls,
        controls: Object.freeze([...screen.regions.coreControls.controls]),
      }),
      sourceControls: Object.freeze({
        ...screen.regions.sourceControls,
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
        coreControls: {
          selector: "#coreControls",
          controls: ["noiseType", "level", "width", "tilt", "lowCut", "highCut"],
        },
        sourceControls: {
          selector: "#sourceControls",
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
