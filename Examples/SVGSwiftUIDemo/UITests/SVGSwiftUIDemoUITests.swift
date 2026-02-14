import XCTest

final class SVGSwiftUIDemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsCanvasAndControls() {
        let app = launchApp()
        XCTAssertTrue(app.otherElements["demo.canvas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["demo.controls"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["demo.fillToggle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["demo.strokeToggle"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSampleSwitcherAndNodeFieldAreAccessible() {
        let app = launchApp()
        let sampleList = app.segmentedControls["demo.sampleList"]
        XCTAssertTrue(sampleList.waitForExistence(timeout: 5))
        if sampleList.buttons.count > 1 {
            sampleList.buttons.element(boundBy: 1).tap()
        }

        XCTAssertTrue(app.otherElements["demo.nodeIDRow"].waitForExistence(timeout: 5))

        let nodeFieldByID = app.textFields["demo.nodeIDField"]
        let nodeField: XCUIElement
        if nodeFieldByID.waitForExistence(timeout: 2) {
            nodeField = nodeFieldByID
        } else {
            nodeField = app.textFields.firstMatch
            XCTAssertTrue(nodeField.waitForExistence(timeout: 5))
        }

        nodeField.tap()
        nodeField.clearAndEnterText("panel-base")
        XCTAssertTrue(app.staticTexts["Target Node: panel-base"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTogglesCanBeChanged() {
        let app = launchApp()
        let fillToggle = app.switches["demo.fillToggle"]
        XCTAssertTrue(fillToggle.waitForExistence(timeout: 5))
        fillToggle.tap()
        fillToggle.tap()

        let strokeToggle = app.switches["demo.strokeToggle"]
        XCTAssertTrue(strokeToggle.waitForExistence(timeout: 5))
        strokeToggle.tap()
        strokeToggle.tap()
    }

    @MainActor
    func testOffsetSlidersExist() {
        let app = launchApp()
        let offsetXSlider = app.sliders["demo.offsetXSlider"]
        let offsetYSlider = app.sliders["demo.offsetYSlider"]
        XCTAssertTrue(offsetXSlider.waitForExistence(timeout: 5))
        XCTAssertTrue(offsetYSlider.waitForExistence(timeout: 5))

        offsetXSlider.adjust(toNormalizedSliderPosition: 0.8)
        offsetYSlider.adjust(toNormalizedSliderPosition: 0.2)
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }
}

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        tap()
        let deleteString = (value as? String).map { String(repeating: XCUIKeyboardKey.delete.rawValue, count: $0.count) } ?? ""
        if !deleteString.isEmpty {
            typeText(deleteString)
        }
        typeText(text)
    }
}
