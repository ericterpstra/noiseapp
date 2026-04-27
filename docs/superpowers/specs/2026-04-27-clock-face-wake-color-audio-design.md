# Clock Face, Wake Color, and Audio Balance Design

Date: 2026-04-27

## Context

The active product is the native SwiftUI iPad app. Clock appearance and wake behavior are configured through `SleepCompanionCore` settings and rendered in `ClockScreen.swift`. Sound controls are schema-driven in core, while procedural signal generation lives in `SleepToneDSP.swift` and runtime output mapping lives in `SleepAudioEngine.swift`.

The requested work covers three areas:

- Clock face settings need more font choices and a better color picker.
- Wake Time needs a background color setting for the completed wake state.
- Cosmetic UI issues need correction on the clock face and saved-noise alert.
- Output level and fan/hum balance need a louder, more usable sound range.

## Design

Use the existing boundaries and keep persistent settings in core.

Extend `ClockFaceSettings` with a persisted `wakeBackgroundColorHex`. It defaults to white so existing behavior is preserved for older saved settings. Backward-compatible decoding will fill the default when older JSON does not contain the new field.

Expand `ClockFontID` with additional clock font options that map to stable iOS font styles or bundled system font names in the SwiftUI renderer. Existing raw values remain unchanged.

Replace the current tiny text-color swatch row with a reusable clock color control that combines native SwiftUI `ColorPicker` with expanded curated swatches. Use this control for both clock text color and wake background color. Color values continue to persist as hex strings.

When the wake transition completes, render the chosen wake background instead of hard-coded white. The clock text and controls should choose a readable foreground based on the selected wake background brightness.

Fix the saved-noise alert text contrast by applying an app-level text field appearance that is readable in the native light alert. Remove the Settings subtext. Make clock-face controls very low-emphasis after playback starts by reducing material, fill, border, and foreground opacity while keeping them accessible.

For audio, move output loudness mapping into a testable core helper and update the engine to use it. The new mapping should preserve slider clamping but produce more gain through the upper half of the slider than the current squared curve. Rebalance fan DSP so Airflow at 0 has little or no constant floor, while Hum has a stronger usable range and can compete with the fan bed.

## Data Flow

Settings draft edits update `SettingsDraft.settings`. Applying the draft persists the new `ClockFaceSettings`, including wake background color, through `AppSettingsStore`.

`ClockScreen` reads the active settings for the front clock face and the draft settings for the settings workspace preview. Wake rendering uses `settings.clockFace.wakeBackgroundColorHex` only when `isWakeActive` is true.

The audio engine continues receiving `SoundParameters`. `SleepAudioEngine.update(parameters:)` asks a pure helper for output gain and applies it to `mainMixerNode.outputVolume`. Procedural balance remains in `SleepToneDSP`.

## Testing

Add or update Swift package tests for:

- Older settings JSON decoding with a default wake background color.
- Saving and loading the new wake background color.
- Settings draft apply and cancel behavior for wake background edits.
- Clock font cases remaining decodable and displayable.
- Color hex validation/defaulting for persisted colors.
- Output gain mapping being louder than the previous quiet curve at high settings while staying bounded.
- DSP fan/hum balance showing a stronger hum path and no meaningful airflow floor at zero.

Run `swift test` in `ios/SleepCompanionCore`. Build the iPad app with `xcodebuild build-for-testing`, and run UI tests if the requested simulator is available.

## Scope

This change does not add new sound knobs, new sound sources, import/export, cloud sync, or new screens. It keeps the archived Web Audio proof of concept read-only.
