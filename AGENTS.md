# AGENTS.md

## Purpose

This repo is a small Web Audio app that should evolve toward a modular, schema-driven structure. Most of the current implementation is concentrated in `public/app.js`; treat that file as a legacy integration point, not the target architecture.

## Primary Goal

Optimize future work for:

- adding new noise sources
- adding new knobs
- adding new screens or panels
- refactoring safely without audio regressions

## Rules for Future Changes

1. Do not add new controls by only copy-pasting more `querySelector`, `appState`, `bindings`, and `updateLabels` entries.
   Move the app toward a shared control schema instead.

2. Do not duplicate DSP logic across the main-thread fallback and the AudioWorklet implementation.
   Shared noise algorithms should come from one source of truth.

3. Keep the audio engine separate from DOM concerns.
   UI code should describe intent; audio code should own graph construction and parameter updates.

4. Keep source metadata centralized.
   A source definition should own its title, description, defaults, control membership, and routing requirements.

5. Prefer configuration over conditionals.
   Adding a new source or screen should mostly mean registering data, not scattering new `if` branches through unrelated functions.

6. Keep pure helpers pure and testable.
   Frequency mapping, value formatting, schema validation, and source-to-parameter mapping should live in small modules with tests.

7. Preserve the simple runtime unless there is a clear payoff.
   This is currently a no-build static app. Do not add a framework or build system casually; earn that complexity.

## Recommended Boundaries

Target the codebase toward these responsibilities:

- `config/`: source definitions, control schema, screen definitions
- `state/`: defaults, store, selectors, serialization
- `ui/`: rendering, DOM mounting, copy, formatters
- `audio/`: engine lifecycle, graph builder, DSP, routing stages
- `visualizers/`: spectrum and waveform drawing

If a change touches all of those layers at once, the design is probably too coupled.

## Current Module Boundaries

The first incremental schema slice now lives under `public/app/`:

- `public/app/config/sources.js`: source copy, source-specific control membership, generator mode, and current route.
- `public/app/config/controls.js`: control labels, input metadata, defaults, parsers, and value formatters.
- `public/app/config/screens.js`: current screen control regions.
- `public/app/ui/mount-controls.js`: shared DOM mounting for configured controls.
- `public/app/ui/formatters.js`: pure value formatting and slider-to-frequency mapping helpers.

`public/app.js` still owns app state coordination, audio graph setup, parameter application, and visualizers. Treat that as the next boundary to shrink rather than a pattern to extend.

## Adding a New Control

Preferred shape:

1. Define the control in a schema with label, range, default, parser, and formatter.
2. Associate it with one or more sources or screens in configuration.
3. Map it to audio parameters in one place.
4. Render it through shared UI code instead of handwritten markup where practical.
5. Add a small test for formatting, mapping, or schema completeness.

For the current code shape, start in `public/app/config/controls.js`, then add the control to a source in `public/app/config/sources.js` or to a screen region in `public/app/config/screens.js`.

Avoid:

- new global mutable fields without schema entries
- manual duplication across multiple UI update functions
- source-specific DOM lookups embedded inside the audio engine

## Adding a New Source

Preferred shape:

1. Add one source definition with copy, defaults, and control membership.
2. Implement or register its DSP or shaping stage.
3. Wire it into the graph builder through configuration.
4. Add at least one verification point for defaults and parameter mapping.

For the current code shape, source copy and UI membership belong in `public/app/config/sources.js`; audio routing still requires changes in `public/app.js` until the graph builder exists.

Avoid:

- hiding source behavior in scattered special cases
- adding new source-specific branches in unrelated UI code unless you are actively extracting that code

## Adding a New Screen

Preferred shape:

1. Define the screen in a screen registry.
2. Declare which controls, cards, and visualizers it uses.
3. Reuse the same store and audio engine.
4. Keep screen mounting isolated so missing elements do not crash unrelated screens.

Avoid:

- assuming every control exists on every page
- binding listeners globally to elements that may not be mounted

## Testing Expectations

Before claiming a refactor is safe, add or run verification for:

- math helpers
- source registry completeness
- control schema completeness
- any new parameter mapping
- any new route or screen-mount behavior

At minimum, add lightweight smoke coverage before large architecture changes.

## Review Checklist

Before finishing a change, check:

- Is this moving knowledge into one source of truth or spreading it out further?
- Did any DSP behavior get copied into a second place?
- Can a future screen omit unused controls without crashing startup?
- Can a future contributor find a source definition without reading the whole app?
- Did the change reduce or increase the size of `public/app.js`?

## Current Hotspots

Be especially careful around:

- `public/app.js`: currently mixes state, DOM wiring, audio lifecycle, routing, and drawing
- `public/app/config/*.js`: schema changes should stay complete and covered by `test/config.test.js`
- `public/noise-generator.worklet.js`: currently duplicates main-thread DSP behavior
- `server.mjs`: path validation should remain strict and separator-aware

## Documentation Expectation

If you introduce a new module boundary, source registry, or schema, update [README.md](/Users/ericterpstra/Dev/noiseapp/README.md) so the next contributor does not need to rediscover the architecture from code.
