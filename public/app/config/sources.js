const CLASSIC_DETAIL =
  "White, pink, brown, blue, and violet use live spectral synthesis in the browser audio engine. Green and grey add browser-side shaping where the underlying definition varies by convention.";

export const DEFAULT_SOURCE_ID = "fan";

function freezeSource(source) {
  return Object.freeze({
    ...source,
    controls: Object.freeze([...source.controls]),
  });
}

export const SOURCE_DEFINITIONS = Object.freeze(
  [
    {
      id: "fan",
      title: "Sleep Fan",
      selectLabel: "Sleep Fan",
      description:
        "A layered fan-style generator with low rumble, a soft motor hum, and muted airflow so it lands closer to a sleep machine than generic static.",
      detail:
        "Sleep Fan layers filtered airflow, sub rumble, a soft hum, and slow drift so it behaves more like a small room fan or sleep machine than filtered static.",
      controls: ["fanAir", "fanRumble", "fanHum", "fanDrift"],
      generatorMode: "fan",
      route: "direct",
    },
    {
      id: "white",
      title: "White Noise",
      selectLabel: "White",
      description: "Equal power per Hz. Flat, bright, and useful as the neutral reference for the other colors.",
      detail: CLASSIC_DETAIL,
      controls: [],
      generatorMode: "white",
      route: "direct",
    },
    {
      id: "pink",
      title: "Pink Noise",
      selectLabel: "Pink",
      description:
        "Power falls about 3 dB per octave, so each octave carries similar energy and the result sounds smoother than white noise.",
      detail: CLASSIC_DETAIL,
      controls: [],
      generatorMode: "pink",
      route: "direct",
    },
    {
      id: "brown",
      title: "Brown Noise",
      selectLabel: "Brown",
      description:
        "A stronger low-frequency tilt, roughly 6 dB per octave downward. Heavier, softer, and more weighted toward the bottom end.",
      detail: CLASSIC_DETAIL,
      controls: [],
      generatorMode: "brown",
      route: "direct",
    },
    {
      id: "blue",
      title: "Blue Noise",
      selectLabel: "Blue",
      description: "The inverse of pink noise in power slope. Energy climbs toward the top end, so it feels airy and sharp.",
      detail: CLASSIC_DETAIL,
      controls: [],
      generatorMode: "blue",
      route: "direct",
    },
    {
      id: "violet",
      title: "Violet Noise",
      selectLabel: "Violet",
      description: "An even steeper rise toward high frequencies than blue noise, creating a very hiss-forward signal.",
      detail: CLASSIC_DETAIL,
      controls: [],
      generatorMode: "violet",
      route: "direct",
    },
    {
      id: "green",
      title: "Green Noise",
      selectLabel: "Green",
      description:
        "A mid-band focused interpretation of green noise. Use the center and Q controls to sweep where that energy concentrates.",
      detail:
        "Green uses a band-pass focus on live white noise so you can sweep the center band rather than locking into one arbitrary definition.",
      controls: ["greenCenter", "greenQ"],
      generatorMode: "white",
      route: "green",
    },
    {
      id: "grey",
      title: "Grey Noise",
      selectLabel: "Grey",
      description:
        "An approximate equal-loudness contour applied to live white noise. The contour amount lets you exaggerate or relax the ear-compensation curve.",
      detail:
        "Grey noise is modeled as a live white-noise source passed through an approximate equal-loudness compensation curve.",
      controls: ["greyAmount"],
      generatorMode: "white",
      route: "grey",
    },
  ].map(freezeSource),
);

export const SOURCE_BY_ID = Object.freeze(
  Object.fromEntries(SOURCE_DEFINITIONS.map((source) => [source.id, source])),
);

export function getSourceDefinition(sourceId) {
  return SOURCE_BY_ID[sourceId] ?? SOURCE_BY_ID[DEFAULT_SOURCE_ID];
}

export function getSourceOptions() {
  return SOURCE_DEFINITIONS.map((source) => ({
    label: source.selectLabel,
    value: source.id,
  }));
}
