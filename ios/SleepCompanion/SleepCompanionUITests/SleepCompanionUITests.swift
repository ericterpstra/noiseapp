import XCTest

final class SleepCompanionUITests: XCTestCase {
    func testClockLaunchesWithPlayControl() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["clockTime"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(app.frame.width, app.frame.height)
        XCTAssertTrue(app.buttons["playPauseButton"].exists)
    }

    func testSettingsFlipShowsFullScreenSoundControlsAndCanCancel() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["clockTime"].waitForExistence(timeout: 5))
        app.buttons["settingsFlipButton"].tap()

        XCTAssertTrue(app.otherElements["settingsWorkspace"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["soundPreviewButton"].exists)
        XCTAssertTrue(app.sliders["soundControl.level"].exists)
        XCTAssertTrue(app.sliders["soundControl.greenMix"].exists)
        XCTAssertTrue(app.sliders["soundControl.fanAir"].exists)
        XCTAssertTrue(app.sliders["soundControl.highCut"].exists)
        XCTAssertTrue(app.staticTexts["clockPreviewTime"].exists)

        app.buttons["settingsCancelButton"].tap()

        XCTAssertTrue(app.staticTexts["clockTime"].waitForExistence(timeout: 5))
    }

    func testSettingsWorkspaceCanSaveAndLoadLocalPresetDrafts() {
        let app = XCUIApplication()
        app.launch()
        let presetName = "Night Fan \(Int(Date().timeIntervalSince1970))"

        XCTAssertTrue(app.staticTexts["clockTime"].waitForExistence(timeout: 5))
        app.buttons["settingsFlipButton"].tap()

        XCTAssertTrue(app.otherElements["savedPresetsSection"].waitForExistence(timeout: 5))
        let titleField = app.textFields["savedPresetTitleField"]
        XCTAssertTrue(titleField.exists)
        titleField.tap()
        titleField.typeText(presetName)

        let descriptionField = app.textFields["savedPresetDescriptionField"]
        XCTAssertTrue(descriptionField.exists)
        descriptionField.tap()
        descriptionField.typeText("Soft clock and fan blend")

        app.buttons["savedPresetSaveNewButton"].tap()

        XCTAssertTrue(app.staticTexts["savedPresetTitle.\(presetName)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savedPresetLoad.\(presetName)"].exists)
        XCTAssertTrue(app.buttons["savedPresetUpdate.\(presetName)"].exists)
        XCTAssertTrue(app.buttons["savedPresetDuplicate.\(presetName)"].exists)
        XCTAssertTrue(app.buttons["savedPresetDelete.\(presetName)"].exists)

        app.buttons["savedPresetLoad.\(presetName)"].tap()
        app.buttons["settingsCancelButton"].tap()

        XCTAssertTrue(app.staticTexts["clockTime"].waitForExistence(timeout: 5))
    }
}
