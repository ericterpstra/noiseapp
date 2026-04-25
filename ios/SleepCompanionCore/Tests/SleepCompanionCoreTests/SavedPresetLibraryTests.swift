import XCTest
@testable import SleepCompanionCore

final class SavedPresetLibraryTests: XCTestCase {
    func testCreateCapturesSoundAndClockWithoutWakeTime() {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let settings = AppSettings(
            clockFace: ClockFaceSettings(fontID: .serif, colorHex: "#8CC8FF", size: 164, luminosity: 0.72),
            activeSoundPresetID: "soft-green",
            activeSoundParameters: SoundPresetDefinition.bundledPresets[1].parameters,
            wakeTime: WakeTime(hour: 5, minute: 45),
            hasCompletedWakeTransition: true
        )
        var library = SavedPresetLibrary()

        let preset = library.create(
            title: "Morning Fan",
            description: "A brighter saved blend.",
            from: settings,
            now: createdAt,
            makeID: { "preset-1" }
        )

        XCTAssertEqual(preset.id, "preset-1")
        XCTAssertEqual(preset.title, "Morning Fan")
        XCTAssertEqual(preset.description, "A brighter saved blend.")
        XCTAssertEqual(preset.soundParameters, settings.activeSoundParameters)
        XCTAssertEqual(preset.clockFace, settings.clockFace)
        XCTAssertEqual(preset.sourceSoundPresetID, "soft-green")
        XCTAssertEqual(preset.createdAt, createdAt)
        XCTAssertEqual(preset.updatedAt, createdAt)
        XCTAssertEqual(library.presets.map(\.id), ["preset-1"])
    }

    func testEditingHelpersPreserveUniqueIDsAndOrdering() {
        let firstDate = Date(timeIntervalSince1970: 10)
        let secondDate = Date(timeIntervalSince1970: 20)
        let updateDate = Date(timeIntervalSince1970: 30)
        let renameDate = Date(timeIntervalSince1970: 40)
        let duplicateDate = Date(timeIntervalSince1970: 50)
        var library = SavedPresetLibrary()
        let first = library.create(title: "First", description: "One", from: .default, now: firstDate, makeID: { "first" })
        let second = library.create(title: "Second", description: "Two", from: .default, now: secondDate, makeID: { "second" })

        var updatedSettings = AppSettings.default
        updatedSettings.clockFace = ClockFaceSettings(fontID: .monospaced, colorHex: "#78DCE8", size: 148, luminosity: 0.3)
        updatedSettings.activeSoundParameters[.fanHumPitch] = 64
        let updated = library.update(id: first.id, from: updatedSettings, now: updateDate)
        let renamed = library.rename(id: second.id, title: "Second Renamed", description: "Updated text", now: renameDate)
        let duplicate = library.duplicate(id: first.id, now: duplicateDate, makeID: { "first-copy" })
        let deleted = library.delete(id: duplicate?.id ?? "")

        XCTAssertEqual(updated?.createdAt, firstDate)
        XCTAssertEqual(updated?.updatedAt, updateDate)
        XCTAssertEqual(updated?.clockFace, updatedSettings.clockFace)
        XCTAssertEqual(renamed?.title, "Second Renamed")
        XCTAssertEqual(renamed?.description, "Updated text")
        XCTAssertEqual(renamed?.updatedAt, renameDate)
        XCTAssertEqual(duplicate?.title, "First Copy")
        XCTAssertEqual(duplicate?.createdAt, duplicateDate)
        XCTAssertEqual(deleted?.id, "first-copy")
        XCTAssertEqual(library.presets.map(\.id), [first.id, second.id])
    }

    func testInitializerDropsDuplicateIDsAfterFirstOccurrence() {
        let date = Date(timeIntervalSince1970: 1)
        let first = SavedPresetDefinition(
            id: "duplicate",
            title: "First",
            description: "",
            soundParameters: .defaultControlValues,
            clockFace: .default,
            sourceSoundPresetID: nil,
            createdAt: date,
            updatedAt: date
        )
        let second = SavedPresetDefinition(
            id: "duplicate",
            title: "Second",
            description: "",
            soundParameters: .defaultControlValues,
            clockFace: .default,
            sourceSoundPresetID: nil,
            createdAt: date,
            updatedAt: date
        )

        let library = SavedPresetLibrary(presets: [first, second])

        XCTAssertEqual(library.presets.map(\.title), ["First"])
    }
}
