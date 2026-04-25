import XCTest
@testable import SleepCompanionCore

final class SavedPresetStoreTests: XCTestCase {
    func testLoadReturnsEmptyLibraryWhenPresetFileIsMissing() throws {
        let store = SavedPresetStore(fileURL: temporaryPresetURL())

        let library = try store.load()

        XCTAssertTrue(library.presets.isEmpty)
    }

    func testSaveAndLoadRoundTripsLibrary() throws {
        let store = SavedPresetStore(fileURL: temporaryPresetURL())
        var library = SavedPresetLibrary()
        _ = library.create(title: "Saved", description: "Local preset", from: .default, now: Date(timeIntervalSince1970: 100), makeID: { "saved-1" })

        try store.save(library)

        XCTAssertEqual(try store.load(), library)
    }

    func testLoadFallsBackToEmptyLibraryWhenFileCannotDecode() throws {
        let fileURL = temporaryPresetURL()
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: fileURL)
        let store = SavedPresetStore(fileURL: fileURL)

        XCTAssertTrue(try store.load().presets.isEmpty)
    }

    private func temporaryPresetURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("presets.json")
    }
}
