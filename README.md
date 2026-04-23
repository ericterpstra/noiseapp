# Noise Lab

Noise Lab is a small browser-based noise generator built with the Web Audio API. It serves a single-page interface that can synthesize white, pink, brown, blue, violet, green, grey, and fan-like sleep noise in real time, then shape the result with filters, stereo width, and per-mode controls.

## Run Locally

Requirements:
- Node.js 18+ is a reasonable baseline.

Start the app:

```bash
npm start
```

Then open [http://localhost:8060](http://localhost:8060).

Run the lightweight schema tests:

```bash
npm test
```

## Current Repo Layout

- `server.mjs`: minimal static file server for the `public/` directory.
- `public/index.html`: the current one-screen UI shell.
- `public/app.js`: application bootstrap, state coordination, audio graph setup, and visualizers.
- `public/app/audio/`: shared audio parameter helpers used by both the main-thread fallback and the AudioWorklet where practical.
- `public/app/config/`: source definitions, control schema, and screen definitions used to mount the current UI.
- `public/app/ui/`: shared UI helpers such as control mounting and value formatting.
- `public/noise-generator.worklet.js`: AudioWorklet DSP implementation.
- `public/styles.css`: styling for the current interface.
- `test/`: Node test coverage for schema completeness and helper behavior.

## How It Works Today

1. `server.mjs` serves the static frontend.
2. `public/app.js` mounts the page controls from config, owns the mutable app state, creates the audio graph, and draws the visualizers.
3. The generator prefers `AudioWorkletNode` and falls back to `ScriptProcessorNode` when needed.
4. Shared fan/green parameter helpers live in `public/app/audio/tone-shaping.js`; the core sample generation still exists in both the fallback and worklet.
5. Green and grey are implemented as post-processing chains over a white-noise source; the other colors are synthesized directly.

## Review Summary

The app is small, readable, and easy to run. The first schema slice removes the old parallel edits across HTML, state defaults, DOM lookups, event bindings, labels, and source copy for the existing controls, but deeper source and audio changes still require coordinated edits in `public/app.js` and the worklet.

### Main Maintainability Risks

1. DSP logic is duplicated in `public/app.js` and `public/noise-generator.worklet.js`.
   The pink, brown, fan, blue, and violet generators exist in two places. Shared fan gain/pitch constants now live in `public/app/audio/tone-shaping.js`, but the sample algorithms can still drift unless they are extracted or covered more deeply.

2. Audio parameter mapping is still concentrated in `public/app.js`.
   Controls now have a schema for defaults, parsing, formatting, and UI mounting, but audio parameter application still happens imperatively inside `NoiseLab.applyState()`.

3. The audio graph is encoded as imperative special cases.
   `NoiseLab` owns the entire routing setup and switches behavior with mode-specific branches. This makes every new post-processing path more invasive than it needs to be.

4. UI state and audio routing are only partially decoupled.
   Source copy and control visibility now live in `public/app/config/sources.js`, but audio behavior still depends on branches and parameter writes inside `NoiseLab`.

5. Automated verification is still lightweight.
   The repo now has Node tests for source, control, and screen configuration, but it still lacks browser smoke coverage and DSP regression tests.

6. `server.mjs` should tighten its path traversal guard.
   The `startsWith(publicDir)` check is string-based and should eventually be replaced with a separator-aware `path.relative()` validation.

## Recommended Direction

If the app is going to grow into multiple screens and more parameters, it should move toward a declarative architecture with one source of truth for controls and source definitions.

### 1. Continue the Source Registry

`public/app/config/sources.js` now defines the first source registry slice:

- `id`
- display name
- description
- which controls belong to it
- whether it is a direct generator or a shaped variant through `generatorMode`
- which current route it needs

The next step is to move more routing/stage behavior into data so the registry also replaces scattered conditionals such as:
- source descriptions
- detail hints
- special routing branches

### 2. Extend the Control Schema

`public/app/config/controls.js` now declares the current controls once with metadata such as:

- `id`
- label
- input type
- min/max/step
- default value
- parser
- formatter

The current screen renders and labels controls from that schema. Audio mapping functions and richer visibility predicates are still future work.

### 3. Split `public/app.js` by Responsibility

The current `public/app.js` is doing too much. A better target is:

```text
public/
  app/
    state/
      store.js
      defaults.js
      selectors.js
    config/
      sources.js
      controls.js
      screens.js
    ui/
      mount-controls.js
      mount-screens.js
      copy.js
      formatters.js
    audio/
      create-engine.js
      graph-builder.js
      routes.js
      dsp-core.js
      noise-generator.worklet.js
    visualizers/
      spectrum.js
      scope.js
```

A split like this lets the repo grow without turning one file into a permanent integration bottleneck.

### 4. Make the Audio Graph Composable

Instead of baking green and grey directly into `NoiseLab`, model the graph as reusable stages:

- source generator
- global shaping
- mode-specific shaping
- stereo stage
- master gain
- analyzers

Then a source definition can say which stages it uses. Adding a new shaped source becomes configuration plus a focused stage implementation, not a series of edits across constructor state and reconnect logic.

### 5. Keep DSP Single-Sourced

The core sample-generation functions should live in one shared module that both the worklet and fallback path can use. If a browser constraint prevents literal sharing, keep one implementation authoritative and generate or mirror the fallback from it with strong tests.

### 6. Add Lightweight Tests Before Refactoring Deeply

Good first tests:

- slider-to-frequency mapping
- value formatting helpers
- source registry completeness
- control schema completeness
- a smoke test that every declared control can be found or rendered
- a smoke test that every source definition has copy and valid control membership

This does not need a heavy framework. Even a small browser-oriented test setup will materially reduce refactor risk.

## Suggested Refactor Order

1. Extract pure helpers from `public/app.js` into small modules without changing behavior. Started with value formatters.
2. Move source descriptions and per-source control membership into a shared source registry. Started in `public/app/config/sources.js`.
3. Move control definitions into a control schema and render the current screen from that schema. Started in `public/app/config/controls.js`, `public/app/config/screens.js`, and `public/app/ui/mount-controls.js`.
4. Move the remaining audio parameter mapping out of `NoiseLab.applyState()` and into one mapping layer. Started with `public/app/audio/tone-shaping.js`.
5. Split `NoiseLab` into an audio engine and a UI/controller layer.
6. Extract shared DSP code so the worklet and fallback stop diverging.
7. Add route or tab support on top of the schema/store model.

## What “Adding a New Knob” Should Eventually Look Like

The desired workflow is:

1. Add one control entry to the schema.
2. Add or update one source definition to reference that control.
3. Add one audio mapping function or graph stage if needed.
4. Add one formatter or reuse an existing formatter.
5. Add one test for the new behavior.

If a future change still requires touching HTML, selectors, state defaults, bindings, labels, and routing by hand, the architecture has not been cleaned up enough.

## What “Adding a New Screen” Should Eventually Look Like

The desired workflow is:

1. Add one screen definition describing title, copy, and which controls or cards it contains.
2. Mount the screen through a screen registry or router.
3. Reuse shared state and audio engine modules without duplicating control bindings.

That keeps screen growth mostly in configuration and composition, not in copy-pasted event wiring.

## Near-Term Priorities

- Break `public/app.js` into smaller modules before adding more product surface area.
- Stop duplicating DSP logic.
- Extend the control schema into audio parameter mapping.
- Add minimal automated checks before large refactors.

## Contributor Guidance

See [AGENTS.md](/Users/ericterpstra/Dev/noiseapp/AGENTS.md) for repo-specific implementation guidance and guardrails for future changes.
