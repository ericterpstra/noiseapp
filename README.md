# Sleep Companion

Sleep Companion is a native SwiftUI iPad app for overnight sleep sound and clock display. It targets iPad landscape orientation, runs offline, generates procedural sleep noise with AVAudioEngine, and keeps the clock screen available as the primary experience.

The old Web Audio proof of concept has been archived under `archive/web-poc/`. It remains useful for sound-design reference, but it is no longer the active product path or root workflow.

## Run And Test

Requirements:

- Xcode with iOS Simulator support.
- Swift toolchain compatible with the Xcode project.

Run the native core tests:

```bash
cd ios/SleepCompanionCore
swift test
```

Build the iPad app for the iOS Simulator:

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

Run UI tests on an available iPad simulator:

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

Run the app on the regular iPad simulator:

```bash
/bin/zsh -lc 'set -e; DEVICE="95138C28-2AD3-4D11-B539-FE7F0DD72F8F"; APP="/tmp/noiseapp-derived/Build/Products/Debug-iphonesimulator/SleepCompanion.app"; xcodebuild -project ios/SleepCompanion/SleepCompanion.xcodeproj -scheme SleepCompanion -configuration Debug -destination "platform=iOS Simulator,name=iPad (A16),OS=26.4.1" -derivedDataPath /tmp/noiseapp-derived CODE_SIGNING_ALLOWED=NO build; xcrun simctl boot "$DEVICE" 2>/dev/null || true; xcrun simctl bootstatus "$DEVICE"; open -a Simulator --args -CurrentDeviceUDID "$DEVICE"; xcrun simctl install "$DEVICE" "$APP"; xcrun simctl launch "$DEVICE" com.example.SleepCompanion'
```

The explicit `open -a Simulator` step brings the simulator window forward. `xcrun simctl launch` starts the app process, but it can do that without opening or focusing the Simulator GUI.

## Test On A Physical iPad

1. Open `ios/SleepCompanion/SleepCompanion.xcodeproj` in Xcode.
2. Select the `SleepCompanion` scheme.
3. Connect the iPad over USB or pair it wirelessly in Xcode's Devices and Simulators window.
4. In the project target's Signing & Capabilities tab, choose your Apple Developer Team. Xcode will replace the placeholder bundle signing setup for local device builds.
5. Select the connected iPad as the run destination.
6. Hold the iPad in landscape, then click Run.
7. Confirm launch behavior: clock opens in landscape, the display stays awake, the play button starts sleep noise, the gear flips to settings, `Cancel` returns without committing draft changes, and `Apply` commits changed clock/sound settings.
8. For an overnight QA pass, plug the iPad into power, disable Focus/notifications as needed, start a sound, leave the app foregrounded, and verify audio stability, screen wake behavior, wake transition, and settings restore after relaunch.

Physical-device builds require a valid signing team and a trusted developer certificate on the iPad. If iPadOS blocks the first launch, open Settings on the iPad and trust the developer profile shown for your Apple ID or team.

## Current Repo Layout

- `ios/SleepCompanionCore/`: Swift package for testable settings, wake-time logic, sound presets, frequency mapping, control schema, draft editing, and procedural DSP.
- `ios/SleepCompanion/`: SwiftUI iPad app shell, AVAudioEngine playback, landscape-only project settings, and UI tests.
- `archive/web-poc/`: historical Web Audio proof of concept, including its old Node server, static app, and Node tests.

## Native App Behavior

The app opens to a centered digital clock on a black background. The display stays awake while the clock is active, vertical swipes adjust clock luminosity, and the translucent bottom play button starts or pauses procedural sleep noise.

Tapping the gear flips the clock over into a full-screen landscape settings workspace. The settings side edits a draft copy of the active settings:

- Left panel: bundled sound preset picker, preview play/stop, and all procedural sound controls.
- Right panel: live clock-face preview, clock customization controls, and compact wake-time editing.
- `Apply` commits the draft, persists settings, updates active audio parameters, and flips back.
- `Cancel` discards the draft and restores the prior active audio state if preview was running.

Wake behavior is silent: when the wake time fires while the app is foregrounded, sleep noise stops, clock luminosity goes to full, and the background changes from black to white.

## Sound Controls

Swift now owns the procedural sound-control schema in `SleepCompanionCore`.

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

When adding a new sound knob, add it to the native control schema, expose typed get/set behavior on `SoundParameters`, wire it through the settings workspace, and add focused Swift package coverage for defaults, formatting, and parameter mapping.

## Archived Web PoC

The archived Web Audio app can still be inspected or run from `archive/web-poc/` if needed:

```bash
cd archive/web-poc
npm test
npm start
```

Do not add new product behavior to the archived PoC. Future product work should happen in the Swift app unless there is an explicit decision to prototype separately.

## Contributor Guidance

See [AGENTS.md](/Users/ericterpstra/Dev/noiseapp/AGENTS.md) for repo-specific implementation guidance and guardrails for future changes.
