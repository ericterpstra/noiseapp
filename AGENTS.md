# AGENTS.md

## Purpose

This repo is now a native SwiftUI iPad app for a sleep companion experience. The old Web Audio/Node proof of concept lives under `archive/web-poc/` as historical reference only.

The active product path is:

- `ios/SleepCompanionCore/`: testable Swift core package.
- `ios/SleepCompanion/`: SwiftUI iPad app and UI tests.

## Primary Goal

Optimize future work for:

- adding procedural sound controls
- adding new procedural sound sources
- evolving the full-screen iPad settings workspace
- refactoring safely without audio regressions
- keeping the overnight clock experience reliable

## Rules For Future Changes

1. Do not add new sound knobs only as handwritten SwiftUI controls.
   Add them to the native sound-control schema first.

2. Keep procedural DSP separate from SwiftUI.
   UI code should describe user intent; audio code should own graph construction, parameter updates, and rendering.

3. Keep sound metadata centralized.
   A sound preset or source definition should own its title, description, defaults, and parameter membership.

4. Prefer configuration over conditionals.
   Adding a new control should mostly mean registering schema data and mapping it through typed helpers.

5. Keep pure helpers pure and testable.
   Frequency mapping, value formatting, control schema completeness, draft application, and source-to-parameter mapping belong in `SleepCompanionCore` with tests.

6. Keep the archived Web Audio PoC read-only for product purposes.
   Do not add active product behavior to `archive/web-poc/` unless the user explicitly asks for a separate prototype.

## Current Module Boundaries

- `ios/SleepCompanionCore/Sources/SleepCompanionCore/SoundParameters.swift`: procedural parameter model, sound parameter IDs, native control definitions, value formatting, and typed get/set access.
- `ios/SleepCompanionCore/Sources/SleepCompanionCore/SoundPresetDefinition.swift`: bundled procedural presets. Presets are parameter definitions, not audio assets.
- `ios/SleepCompanionCore/Sources/SleepCompanionCore/AppSettings.swift`: persisted app settings and pure draft-editing model.
- `ios/SleepCompanionCore/Sources/SleepCompanionCore/SleepToneDSP.swift`: procedural sleep-tone sample generation.
- `ios/SleepCompanion/SleepCompanion/SleepAudioEngine.swift`: AVAudioEngine lifecycle, graph setup, EQ mapping, and render-node connection.
- `ios/SleepCompanion/SleepCompanion/SleepAppModel.swift`: app state coordination, persistence, wake transitions, playback, settings draft lifecycle, and preview audition.
- `ios/SleepCompanion/SleepCompanion/ClockScreen.swift`: front clock display and back-side full-screen settings workspace.

If a change touches all of these layers at once, the design is probably too coupled.

## Adding A New Sound Control

Preferred shape:

1. Add a `SoundParameterID`.
2. Add one `SoundControlDefinition` with label, group, range, step, default, and formatter behavior.
3. Add typed get/set support on `SoundParameters`.
4. Map the parameter to DSP or AVAudioEngine behavior in one place.
5. Add Swift package tests for schema completeness, formatting, clamping, and parameter mapping.
6. Let the settings workspace render it through the shared schema-driven sound control UI.

Avoid:

- source-specific UI branches for generic controls
- duplicating value formatting in SwiftUI
- adding mutable app state without Codable persistence or draft semantics
- adding controls that cannot be omitted or rearranged safely

## Adding A New Sound Source Or Preset

Preferred shape:

1. Add one source or preset definition with copy, defaults, and procedural parameters.
2. Implement or register its DSP behavior without duplicating existing algorithms.
3. Wire it into the audio engine through typed configuration.
4. Add at least one verification point for defaults and parameter mapping.

Avoid:

- hiding source behavior in scattered SwiftUI conditions
- adding bundled audio loops for current procedural-only features
- changing persisted settings without fallback coverage

## Adding A New Screen Or Panel

Preferred shape:

1. Keep the clock screen as the first-run and overnight default.
2. Add new panels as isolated SwiftUI views with clear model methods.
3. Use draft editing when a screen previews changes before applying.
4. Keep missing optional controls from crashing startup or preview.

Avoid:

- modal settings sheets for the main iPad settings workflow
- card-in-card layouts
- global bindings that assume every control exists on every screen

## Testing Expectations

Before claiming a change is safe, add or run verification for:

- Swift package tests for pure core logic
- control schema completeness
- parameter formatting and clamping
- settings draft apply/cancel behavior
- audio parameter update paths
- iPad UI tests for clock launch and settings workspace behavior

Primary verification commands:

```bash
cd ios/SleepCompanionCore
swift test
```

```bash
xcodebuild \
  -project ios/SleepCompanion/SleepCompanion.xcodeproj \
  -scheme SleepCompanion \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/noiseapp-derived \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

```bash
xcodebuild \
  -project ios/SleepCompanion/SleepCompanion.xcodeproj \
  -scheme SleepCompanion \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPad (A16),OS=26.4.1' \
  -derivedDataPath /tmp/noiseapp-derived \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
```

## Review Checklist

Before finishing a change, check:

- Is sound/control knowledge moving into one source of truth?
- Did any DSP behavior get copied?
- Can future settings panels omit unused controls without crashing?
- Can a future contributor find a preset or control definition without reading the whole app?
- Did the change preserve the foreground overnight clock path?
- Did README.md change if architecture or workflows changed?
