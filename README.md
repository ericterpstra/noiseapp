# Sleep Tone

Sleep Tone is a small browser-based sleep sound generator built with the Web Audio API. It synthesizes one continuous hybrid tone: a fan-like bed with airflow, rumble, hum, slow movement, warmth, high/low cuts, stereo width, and an optional green-noise layer.

The app is still a no-build static project. Keep it that way unless a future change earns the extra complexity.

## Run Locally

Requirements:
- Node.js 18+ is a reasonable baseline.

Start the app:

```bash
npm start
```

Then open [http://localhost:8060](http://localhost:8060).

Run the lightweight tests:

```bash
npm test
```

## Current Repo Layout

- `server.mjs`: minimal static file server for the `public/` directory.
- `public/index.html`: the single-screen sleep tone UI shell.
- `public/app.js`: application bootstrap, state coordination, audio graph setup, and control binding.
- `public/app/audio/sleep-tone-dsp.js`: shared sleep-tone sample generation used by both the main-thread fallback and the AudioWorklet.
- `public/app/audio/tone-shaping.js`: pure fan and shaping helpers used by the shared DSP.
- `public/app/config/`: source, control, and screen schema used to mount the current UI.
- `public/app/state/presets.js`: versioned preset payload serialization and normalization for future save/load UI.
- `public/app/ui/`: shared UI helpers such as control mounting and value formatting.
- `public/noise-generator.worklet.js`: AudioWorklet wrapper around the shared sleep-tone DSP.
- `public/styles.css`: styling for the current interface.
- `test/`: Node test coverage for schema completeness, DSP helpers, and preset payload behavior.

## How It Works Today

1. `server.mjs` serves the static frontend.
2. `public/app.js` mounts controls from configuration, owns the mutable runtime state, creates the Web Audio graph, and applies state to audio parameters.
3. The generator prefers `AudioWorkletNode` and falls back to `ScriptProcessorNode` when needed.
4. Both audio backends call the same sleep-tone DSP helpers from `public/app/audio/sleep-tone-dsp.js`.
5. `greenMix` is part of the sleep-tone generator itself. At `0`, the green layer contributes no signal.
6. Preset save/load is not visible yet, but `public/app/state/presets.js` defines the v1 payload shape and normalization rules.

## Control Schema

The active control surface is defined in `public/app/config/controls.js` and mounted through `public/app/config/screens.js`.

Current controls:

- `level`
- `greenMix`
- `fanAir`
- `fanRumble`
- `fanHum`
- `fanHumPitch`
- `fanDrift`
- `warmth`
- `lowCut`
- `highCut`
- `width`

When adding a new knob, define the control once in the schema, add it to the sleep source/screen configuration, map it to audio behavior in one place, and add focused test coverage.

## Preset Payloads

The future save/load UI should use the helpers in `public/app/state/presets.js` instead of reading or writing raw state directly.

```js
{
  kind: "sleep-tone-preset",
  version: 1,
  values: {
    level,
    greenMix,
    fanAir,
    fanRumble,
    fanHum,
    fanHumPitch,
    fanDrift,
    warmth,
    lowCut,
    highCut,
    width
  }
}
```

`readPresetPayload()` ignores unknown keys, fills missing values from defaults, clamps numeric values to schema ranges, and returns `null` for unrelated payloads.

## Contributor Guidance

See [AGENTS.md](/Users/ericterpstra/Dev/noiseapp/AGENTS.md) for repo-specific implementation guidance and guardrails for future changes.
