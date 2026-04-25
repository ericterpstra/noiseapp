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
        XCTAssertFalse(app.buttons["soundPreviewButton"].exists)
        XCTAssertTrue(app.buttons["noisePresetPicker"].exists)
        XCTAssertTrue(app.sliders["soundControl.level"].exists)
        XCTAssertTrue(app.sliders["soundControl.greenMix"].exists)
        XCTAssertTrue(app.sliders["soundControl.fanAir"].exists)
        XCTAssertTrue(app.sliders["soundControl.highCut"].exists)
        XCTAssertTrue(app.buttons["noisePresetSaveButton"].exists)
        XCTAssertTrue(app.buttons["noisePresetSaveAsButton"].exists)
        XCTAssertTrue(app.buttons["noisePresetDeleteButton"].exists)
        XCTAssertTrue(app.staticTexts["clockPreviewTime"].exists)

        app.buttons["settingsCancelButton"].tap()

        XCTAssertTrue(app.staticTexts["clockTime"].waitForExistence(timeout: 5))
    }

    func testSettingsWorkspaceCanSaveNewNoiseFromEditedControls() {
        let app = XCUIApplication()
        app.launch()
        let presetName = "Night Fan \(Int(Date().timeIntervalSince1970))"

        XCTAssertTrue(app.staticTexts["clockTime"].waitForExistence(timeout: 5))
        app.buttons["settingsFlipButton"].tap()

        XCTAssertFalse(app.otherElements["savedPresetsSection"].exists)
        XCTAssertTrue(app.sliders["soundControl.level"].waitForExistence(timeout: 5))
        app.sliders["soundControl.level"].adjust(toNormalizedSliderPosition: 0.7)
        XCTAssertTrue(app.buttons["noisePresetSaveAsButton"].isEnabled)
        app.buttons["noisePresetSaveAsButton"].tap()

        let saveAsAlert = app.alerts["Save as new noise"]
        XCTAssertTrue(saveAsAlert.waitForExistence(timeout: 5))
        let titleField = saveAsAlert.textFields["Name"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(presetName)
        saveAsAlert.buttons["Save"].tap()

        app.buttons["noisePresetPicker"].tap()
        XCTAssertTrue(app.buttons[presetName].waitForExistence(timeout: 5))
        app.buttons[presetName].tap()
        XCTAssertTrue(app.buttons["noisePresetDeleteButton"].isEnabled)
        app.buttons["settingsCancelButton"].tap()

        XCTAssertTrue(app.staticTexts["clockTime"].waitForExistence(timeout: 5))
    }
}
