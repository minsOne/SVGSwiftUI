import XCTest

final class SVGSwiftUIDemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDemoScreenShowsSamples() {
        let app = launchApp()
        XCTAssertTrue(app.otherElements["demo.content"].waitForExistence(timeout: 5))

        let requiredCanvases = [
            "demo.canvas.badge",
            "demo.canvas.panel",
            "demo.canvas.animation-pulse",
            "demo.canvas.animation-drift",
            "demo.canvas.mesh-network",
            "demo.canvas.spiral-paths",
            "demo.canvas.orbital-lattice",
            "demo.canvas.animation-luminous-core",
            "demo.canvas.aurora-wave",
            "demo.canvas.dense-grid-world",
            "demo.canvas.polyline-ribbon",
            "demo.canvas.constellation-grid",
            "demo.canvas.transform-radial-spiral"
        ]

        for canvasID in requiredCanvases {
            XCTAssertTrue(app.otherElements[canvasID].waitForExistence(timeout: 10))
        }
    }

    @MainActor
    func testAnimationToggleIsAvailableForAnimatedSamples() {
        let app = launchApp()
        let pulseToggle = app.switches["demo.animationToggle.animation-pulse"]
        let driftToggle = app.switches["demo.animationToggle.animation-drift"]
        let luminousToggle = app.switches["demo.animationToggle.animation-luminous-core"]

        XCTAssertTrue(pulseToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(driftToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(luminousToggle.waitForExistence(timeout: 5))

        let initialPulseState = pulseToggle.value as? String
        pulseToggle.tap()
        waitForRenderSettled()
        let newPulseState = pulseToggle.value as? String
        if let initialPulseState {
            XCTAssertNotEqual(initialPulseState, newPulseState)
        }

        let initialLuminousState = luminousToggle.value as? String
        luminousToggle.tap()
        waitForRenderSettled()
        let newLuminousState = luminousToggle.value as? String
        if let initialLuminousState {
            XCTAssertNotEqual(initialLuminousState, newLuminousState)
        }
    }

    @MainActor
    func testInlineCodeCanBeExpanded() {
        let app = launchApp()
        let pulseCodeButton = app.buttons["demo.codeDisclosure.animation-pulse"]
        XCTAssertTrue(pulseCodeButton.waitForExistence(timeout: 5))
        pulseCodeButton.tap()

        let sampleCode = app.staticTexts["demo.source.animation-pulse"]
        XCTAssertTrue(sampleCode.waitForExistence(timeout: 5))

        if sampleCode.waitForExistence(timeout: 1) {
            let firstLineContains = sampleCode.label.contains("<svg")
            XCTAssertTrue(firstLineContains)
        }
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    private func waitForRenderSettled() {
        let delayInMicroseconds: useconds_t = 250_000
        usleep(delayInMicroseconds)
    }
}
