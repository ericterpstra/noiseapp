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
}
