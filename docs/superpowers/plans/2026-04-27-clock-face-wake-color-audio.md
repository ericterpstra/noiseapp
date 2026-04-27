# Clock Face Wake Color Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add richer clock appearance controls, persisted wake background color, quieter clock controls during playback, readable modal text, and louder better-balanced procedural sound.

**Architecture:** Keep persisted appearance and pure helpers in `SleepCompanionCore`. Keep SwiftUI responsible for rendering controls from those settings. Keep audio output gain and procedural fan/hum balance out of SwiftUI.

**Tech Stack:** Swift 5, SwiftUI, AVFoundation, XCTest, Xcode iPad app target.

---

## File Structure

- Modify `ios/SleepCompanionCore/Sources/SleepCompanionCore/ClockFaceSettings.swift` for additional font IDs, wake background persistence, color normalization, and brightness helpers.
- Modify `ios/SleepCompanionCore/Sources/SleepCompanionCore/SoundParameters.swift` for a testable output gain mapping helper.
- Modify `ios/SleepCompanionCore/Sources/SleepCompanionCore/SleepToneDSP.swift` for fan air and hum balance helpers used by rendering and tests.
- Modify `ios/SleepCompanionCore/Tests/SleepCompanionCoreTests/AppSettingsStoreTests.swift` for backward-compatible persisted settings.
- Modify `ios/SleepCompanionCore/Tests/SleepCompanionCoreTests/SettingsDraftTests.swift` for draft wake background apply/cancel behavior.
- Modify `ios/SleepCompanionCore/Tests/SleepCompanionCoreTests/SleepToneDSPTests.swift` for output gain and fan/hum balance.
- Modify `ios/SleepCompanion/SleepCompanion/ColorHex.swift` for SwiftUI color round-tripping and expanded swatches.
- Modify `ios/SleepCompanion/SleepCompanion/ClockScreen.swift` for new controls, wake rendering, and subdued playback controls.
- Modify `ios/SleepCompanion/SleepCompanion/AppDelegate.swift` for readable native alert text fields.
- Modify `ios/SleepCompanion/SleepCompanion/SleepAudioEngine.swift` to use the pure gain helper.
- Modify `ios/SleepCompanion/SleepCompanionUITests/SleepCompanionUITests.swift` for visible UI controls.

### Task 1: Core Clock Appearance Settings

**Files:**
- Modify: `ios/SleepCompanionCore/Sources/SleepCompanionCore/ClockFaceSettings.swift`
- Test: `ios/SleepCompanionCore/Tests/SleepCompanionCoreTests/AppSettingsStoreTests.swift`
- Test: `ios/SleepCompanionCore/Tests/SleepCompanionCoreTests/SettingsDraftTests.swift`

- [ ] **Step 1: Write failing persistence and draft tests**

Add assertions that default settings include `wakeBackgroundColorHex == "#FFFFFF"`, save/load preserves a custom wake background, older JSON without the field decodes with the default, invalid color strings fall back to safe defaults, all font cases are present, and draft apply/cancel preserves the new field.

- [ ] **Step 2: Run tests to verify failure**

Run: `cd ios/SleepCompanionCore && swift test --filter AppSettingsStoreTests --filter SettingsDraftTests`

Expected: fails because `wakeBackgroundColorHex`, new font cases, and color helper behavior do not exist.

- [ ] **Step 3: Implement minimal core settings support**

Add `wakeBackgroundColorHex` to `ClockFaceSettings`, implement manual Codable fallback for older JSON, normalize 6-digit hex values to uppercase `#RRGGBB`, add `ClockColorHex` helpers, and add extra `ClockFontID` cases without changing existing raw values.

- [ ] **Step 4: Run tests to verify pass**

Run: `cd ios/SleepCompanionCore && swift test --filter AppSettingsStoreTests --filter SettingsDraftTests`

Expected: selected tests pass.

### Task 2: Output Gain and Fan/Hum Balance

**Files:**
- Modify: `ios/SleepCompanionCore/Sources/SleepCompanionCore/SoundParameters.swift`
- Modify: `ios/SleepCompanionCore/Sources/SleepCompanionCore/SleepToneDSP.swift`
- Modify: `ios/SleepCompanion/SleepCompanion/SleepAudioEngine.swift`
- Test: `ios/SleepCompanionCore/Tests/SleepCompanionCoreTests/SleepToneDSPTests.swift`

- [ ] **Step 1: Write failing audio tests**

Add tests for `SoundOutputMapping.mixerOutputVolume(level:)` returning `0` at level `0`, `1` at level `1`, clamping out-of-range values, and being louder than the old `pow(level, 2) * 0.9` curve at `0.75`. Add tests for airflow having no floor at `0` and maximum hum being stronger than maximum airflow.

- [ ] **Step 2: Run tests to verify failure**

Run: `cd ios/SleepCompanionCore && swift test --filter SleepToneDSPTests`

Expected: fails because output mapping and accessible fan/hum helper methods do not exist.

- [ ] **Step 3: Implement minimal audio changes**

Add `SoundOutputMapping.mixerOutputVolume(level:)` using a bounded `pow(level, 1.15)` curve. Replace `SleepAudioEngine` mixer volume mapping with the helper. Expose internal DSP layer-level helpers and change airflow to no floor while increasing hum range.

- [ ] **Step 4: Run tests to verify pass**

Run: `cd ios/SleepCompanionCore && swift test --filter SleepToneDSPTests`

Expected: selected tests pass.

### Task 3: SwiftUI Appearance Controls and Cosmetics

**Files:**
- Modify: `ios/SleepCompanion/SleepCompanion/ColorHex.swift`
- Modify: `ios/SleepCompanion/SleepCompanion/ClockScreen.swift`
- Modify: `ios/SleepCompanion/SleepCompanion/AppDelegate.swift`
- Test: `ios/SleepCompanion/SleepCompanionUITests/SleepCompanionUITests.swift`

- [ ] **Step 1: Write failing UI test expectations**

Add UI test expectations for a clock text color picker, wake background color picker, and an expanded font picker path.

- [ ] **Step 2: Implement UI support**

Add SwiftUI `Color` to hex conversion, expanded swatches, reusable `ClockColorControl`, wake background picker under Wake Time, clock preview wake background handling, readable foreground selection, app-wide text field tint/text appearance, removal of the Settings subtext, and subdued controls when `isPlaying == true`.

- [ ] **Step 3: Run focused build/test checks**

Run: `cd ios/SleepCompanionCore && swift test`

Run: `xcodebuild -project ios/SleepCompanion/SleepCompanion.xcodeproj -scheme SleepCompanion -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/noiseapp-derived CODE_SIGNING_ALLOWED=NO build-for-testing`

Expected: core tests pass and app builds for testing.

### Task 4: Full Verification and Cleanup

**Files:**
- Review all modified source and test files.

- [ ] **Step 1: Run full core tests**

Run: `cd ios/SleepCompanionCore && swift test`

Expected: all Swift package tests pass.

- [ ] **Step 2: Run app build for testing**

Run: `xcodebuild -project ios/SleepCompanion/SleepCompanion.xcodeproj -scheme SleepCompanion -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/noiseapp-derived CODE_SIGNING_ALLOWED=NO build-for-testing`

Expected: build exits 0.

- [ ] **Step 3: Run iPad UI tests if simulator is available**

Run: `xcrun simctl list devices available | rg 'iPad \\(A16\\).*26\\.4\\.1'`

If present, run: `xcodebuild -project ios/SleepCompanion/SleepCompanion.xcodeproj -scheme SleepCompanion -configuration Debug -destination 'platform=iOS Simulator,name=iPad (A16),OS=26.4.1' -derivedDataPath /tmp/noiseapp-derived CODE_SIGNING_ALLOWED=NO test-without-building`

Expected: UI tests pass when the requested simulator exists.
