export const DEFAULT_SOURCE_ID = "sleepTone";

function freezeSource(source) {
  return Object.freeze({
    ...source,
    controls: Object.freeze([...source.controls]),
  });
}

export const SOURCE_DEFINITIONS = Object.freeze(
  [
    {
      id: "sleepTone",
      title: "Sleep Tone",
      description:
        "A layered sleep tone with fan-like airflow, low rumble, soft hum, and an optional green-noise bed for a deeper ambient texture.",
      detail:
        "Use High Cut for the strongest darker-tone shift, Warmth for a gentler low-end tilt, and Green Layer to blend in or fully remove the soft mid-band bed.",
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
      generatorMode: "sleepTone",
      route: "direct",
    },
  ].map(freezeSource),
);

export const SOURCE_BY_ID = Object.freeze(
  Object.fromEntries(SOURCE_DEFINITIONS.map((source) => [source.id, source])),
);

export function getSourceDefinition(sourceId) {
  return SOURCE_BY_ID[sourceId] ?? SOURCE_BY_ID[DEFAULT_SOURCE_ID];
}
