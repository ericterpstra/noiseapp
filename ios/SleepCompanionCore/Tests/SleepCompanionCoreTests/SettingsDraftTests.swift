import XCTest
@testable import SleepCompanionCore

final class SettingsDraftTests: XCTestCase {
    func testSelectingPresetUpdatesDraftWithoutChangingOriginalSettings() {
        let original = AppSettings.default
        var draft = SettingsDraft(settings: original)
        let preset = SoundPresetDefinition.bundledPresets[1]

        draft.selectSoundPreset(id: preset.id)

        XCTAssertEqual(draft.settings.activeSoundPresetID, preset.id)
        XCTAssertEqual(draft.settings.activeSoundParameters, preset.parameters)
        XCTAssertEqual(original.activeSoundPresetID, SoundPresetDefinition.defaultPreset.id)
        XCTAssertEqual(original.activeSoundParameters, SoundPresetDefinition.defaultPreset.parameters)
    }

    func testSettingSoundParameterMarksSoundAsCustomAndClampsValue() {
        var draft = SettingsDraft(settings: .default)

        draft.setSoundParameter(.level, value: 2)

        XCTAssertEqual(draft.settings.activeSoundPresetID, SoundPresetDefinition.customDraftPresetID)
        XCTAssertEqual(draft.settings.activeSoundParameters.level, 1)
    }

    func testApplyReturnsCommittedDraftSettings() {
        var draft = SettingsDraft(settings: .default)
        draft.setSoundParameter(.fanHumPitch, value: 60)
        draft.setClockFace(
            ClockFaceSettings(
                fontID: .serif,
                colorHex: "#8CC8FF",
                size: 180,
                luminosity: 0.75
            )
        )
        draft.setWakeTime(WakeTime(hour: 6, minute: 30))

        let applied = draft.appliedSettings()

        XCTAssertEqual(applied.activeSoundParameters.fanHumPitch, 60)
        XCTAssertEqual(applied.clockFace.fontID, .serif)
        XCTAssertEqual(applied.clockFace.colorHex, "#8CC8FF")
        XCTAssertEqual(applied.clockFace.size, 180)
        XCTAssertEqual(applied.clockFace.luminosity, 0.75)
        XCTAssertEqual(applied.wakeTime, WakeTime(hour: 6, minute: 30))
    }

    func testCancelReturnsOriginalSettings() {
        let original = AppSettings.default
        var draft = SettingsDraft(settings: original)

        draft.setSoundParameter(.greenMix, value: 0.8)
        draft.setClockFace(ClockFaceSettings(fontID: .monospaced, colorHex: "#FFFFFF", size: 100, luminosity: 0.2))

        XCTAssertEqual(draft.cancelledSettings(), original)
    }

    func testLoadingSavedPresetUpdatesNoiseWithoutChangingClockOrOriginalSettings() {
        let original = AppSettings.default
        let preset = SavedPresetDefinition(
            id: "saved-1",
            title: "Saved",
            description: "Stored sound and clock.",
            soundParameters: SoundPresetDefinition.bundledPresets[2].parameters,
            sourceSoundPresetID: "low-rumble",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2)
        )
        var draft = SettingsDraft(settings: original)

        draft.loadSavedPreset(preset)

        XCTAssertEqual(draft.settings.activeSavedPresetID, "saved-1")
        XCTAssertEqual(draft.settings.activeSoundPresetID, "low-rumble")
        XCTAssertEqual(draft.settings.activeSoundParameters, preset.soundParameters)
        XCTAssertEqual(draft.settings.clockFace, original.clockFace)
        XCTAssertNil(original.activeSavedPresetID)
        XCTAssertEqual(original.clockFace, .default)
    }

    func testEditingSoundClearsBundledPresetAssociationButKeepsSavedNoiseSelection() {
        let preset = SavedPresetDefinition(
            id: "saved-1",
            title: "Saved",
            description: "",
            soundParameters: SoundPresetDefinition.bundledPresets[1].parameters,
            sourceSoundPresetID: "soft-green",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 1)
        )

        var soundDraft = SettingsDraft(settings: .default)
        soundDraft.loadSavedPreset(preset)
        soundDraft.setSoundParameter(.greenMix, value: 0.75)

        XCTAssertEqual(soundDraft.settings.activeSavedPresetID, "saved-1")
        XCTAssertEqual(soundDraft.settings.activeSoundPresetID, SoundPresetDefinition.customDraftPresetID)
    }
}
