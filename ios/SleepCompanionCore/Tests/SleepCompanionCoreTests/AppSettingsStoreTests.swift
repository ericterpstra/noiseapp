import XCTest
@testable import SleepCompanionCore

final class AppSettingsStoreTests: XCTestCase {
    func testLoadReturnsDefaultsWhenSettingsFileIsMissing() throws {
        let store = AppSettingsStore(fileURL: temporarySettingsURL())

        let settings = try store.load()

        XCTAssertEqual(settings, .default)
        XCTAssertEqual(settings.clockFace.fontID, .rounded)
        XCTAssertEqual(settings.clockFace.colorHex, "#F8F2E7")
        XCTAssertEqual(settings.clockFace.size, 132)
        XCTAssertEqual(settings.clockFace.luminosity, 0.42)
        XCTAssertEqual(settings.activeSoundPresetID, "deep-fan")
        XCTAssertEqual(settings.wakeTime, WakeTime(hour: 7, minute: 0))
    }

    func testSaveAndLoadRoundTripsActiveSettings() throws {
        let store = AppSettingsStore(fileURL: temporarySettingsURL())
        let settings = AppSettings(
            clockFace: ClockFaceSettings(
                fontID: .monospaced,
                colorHex: "#78DCE8",
                size: 156,
                luminosity: 0.18
            ),
            activeSoundPresetID: "soft-green",
            activeSoundParameters: SoundPresetDefinition.bundledPresets[1].parameters,
            wakeTime: WakeTime(hour: 6, minute: 45),
            hasCompletedWakeTransition: false
        )

        try store.save(settings)

        XCTAssertEqual(try store.load(), settings)
    }

    func testLoadFallsBackToDefaultsWhenFileCannotDecode() throws {
        let fileURL = temporarySettingsURL()
        try Data("not json".utf8).write(to: fileURL)
        let store = AppSettingsStore(fileURL: fileURL)

        XCTAssertEqual(try store.load(), .default)
    }

    private func temporarySettingsURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("json")
    }
}
