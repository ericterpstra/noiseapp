import XCTest
@testable import SleepCompanionCore

final class AppSettingsStoreTests: XCTestCase {
    func testLoadReturnsDefaultsWhenSettingsFileIsMissing() throws {
        let store = AppSettingsStore(fileURL: temporarySettingsURL())

        let settings = try store.load()

        XCTAssertEqual(settings, .default)
        XCTAssertEqual(settings.clockFace.fontID, .rounded)
        XCTAssertEqual(settings.clockFace.colorHex, "#F8F2E7")
        XCTAssertEqual(settings.clockFace.wakeBackgroundColorHex, "#FFFFFF")
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
                luminosity: 0.18,
                wakeBackgroundColorHex: "#243447"
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

    func testLoadSupportsOlderSettingsJSONWithoutSavedPresetID() throws {
        let fileURL = temporarySettingsURL()
        let json = """
        {
          "activeSoundParameters" : {
            "fanAir" : 0.55,
            "fanDrift" : 0.32,
            "fanHum" : 0.52,
            "fanHumPitch" : 92,
            "fanRumble" : 0.65,
            "greenMix" : 0.25,
            "highCut" : 1,
            "level" : 0.42,
            "lowCut" : 0,
            "warmth" : 0.35,
            "width" : 1
          },
          "activeSoundPresetID" : "deep-fan",
          "clockFace" : {
            "colorHex" : "#F8F2E7",
            "fontID" : "rounded",
            "luminosity" : 0.42,
            "size" : 132
          },
          "hasCompletedWakeTransition" : false,
          "wakeTime" : {
            "hour" : 7,
            "minute" : 0
          }
        }
        """
        try Data(json.utf8).write(to: fileURL)
        let store = AppSettingsStore(fileURL: fileURL)

        let settings = try store.load()

        XCTAssertEqual(settings.activeSoundPresetID, "deep-fan")
        XCTAssertNil(settings.activeSavedPresetID)
        XCTAssertEqual(settings.clockFace.wakeBackgroundColorHex, "#FFFFFF")
    }

    func testClockFaceNormalizesColorHexValues() {
        let settings = ClockFaceSettings(
            fontID: .rounded,
            colorHex: "78dce8",
            size: 132,
            luminosity: 0.42,
            wakeBackgroundColorHex: "not-a-color"
        )

        XCTAssertEqual(settings.colorHex, "#78DCE8")
        XCTAssertEqual(settings.wakeBackgroundColorHex, "#FFFFFF")
        XCTAssertEqual(ClockColorHex.relativeLuminance("#000000"), 0, accuracy: 0.0001)
        XCTAssertEqual(ClockColorHex.relativeLuminance("#FFFFFF"), 1, accuracy: 0.0001)
        XCTAssertFalse(ClockColorHex.isLight("#101010"))
        XCTAssertTrue(ClockColorHex.isLight("#F6F6F6"))
    }

    func testClockFontChoicesIncludeExpandedIpadOptions() {
        XCTAssertEqual(
            ClockFontID.allCases,
            [
                .rounded,
                .monospaced,
                .system,
                .serif,
                .avenirNextCondensed,
                .dinAlternate,
                .futura,
                .gillSans,
                .georgia
            ]
        )
    }

    private func temporarySettingsURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("json")
    }
}
