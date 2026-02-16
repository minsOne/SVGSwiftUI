import Foundation
import UIKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest

extension SVGSwiftUIDemoUITests {
    @MainActor
    func testEnhancedFeatureChecks_forEachSample() {
        let app = launchApp()
        for sampleID in Self.requiredCanvases {
            let isAnimated = Self.animatedCanvases.contains(sampleID)
            let activityTitle = isAnimated
                ? "enhanced-feature-animated-\(sampleID)"
                : "enhanced-feature-static-\(sampleID)"

            XCTContext.runActivity(named: activityTitle) { _ in
                if isAnimated {
                    assertAnimationToggleFunctions(for: sampleID, in: app)
                }
                assertNodeControlsAreInteractive(for: sampleID, in: app)
            }
        }
    }

    @MainActor
    func testAnimationControls_workForEachAnimatedSample() {
        let app = launchApp()
        for sampleID in Self.animatedCanvases {
            XCTContext.runActivity(named: "animation-control-\(sampleID)") { _ in
                assertAnimationToggleFunctions(for: sampleID, in: app)
            }
        }
    }

    @MainActor
    func testAnimationDrift_keepsMovementWhenOffsetOverridden() {
        let app = launchApp()
        let sampleID = "animation-drift"

        guard openSample(sampleID: sampleID, in: app) else {
            XCTFail("샘플 상세 화면으로 이동하지 못했습니다: \(sampleID)")
            return
        }

        let animationToggle = app.switches["demo.animationToggle.\(sampleID)"]
        let overrideToggle = app.switches["demo.nodeOverrideEnabled.\(sampleID)"]
        let offsetXSlider = app.sliders["demo.nodeOffsetX.\(sampleID)"]
        let offsetYSlider = app.sliders["demo.nodeOffsetY.\(sampleID)"]
        let detailContainer = discoverScrollableContainer(in: app)
        guard let canvas = discoverElement(
            identifier: "demo.canvas.\(sampleID)",
            in: app,
            container: detailContainer,
            timeout: 5
        ) else {
            XCTFail("Canvas를 찾지 못했습니다: \(sampleID)")
            closeSampleDetail(in: app)
            return
        }

        XCTAssertTrue(animationToggle.waitForExistence(timeout: 5))
        if boolValue(from: animationToggle) == false {
            animationToggle.tap()
            XCTAssertTrue(waitForToggleValue(animationToggle, expected: true))
        }

        XCTAssertTrue(overrideToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(offsetXSlider.waitForExistence(timeout: 5))
        XCTAssertTrue(offsetYSlider.waitForExistence(timeout: 5))
        if !offsetXSlider.isEnabled {
            XCTAssertTrue(activateSwitch(overrideToggle, expected: true))
        }

        XCTAssertTrue(waitForToggleValue(overrideToggle, expected: true))

        XCTAssertTrue(waitForEnabled(offsetXSlider, timeout: Self.controlEnablePollTimeout))
        XCTAssertTrue(waitForEnabled(offsetYSlider, timeout: Self.controlEnablePollTimeout))

        let baselineCanvas = rasterizedScreenshot(from: canvas, in: app)
        XCTAssertNotNil(baselineCanvas, "초기 캔버스 캡처를 할 수 없습니다.")

        offsetXSlider.adjust(toNormalizedSliderPosition: 0.68)
        _ = waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.4)

        offsetYSlider.adjust(toNormalizedSliderPosition: 0.42)
        _ = waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.4)

        XCTAssertTrue(
            canvasHasVisualMovement(canvas, in: app, timeout: 2.0),
            "\(sampleID)에서 offset override 적용 후에도 애니메이션 이동이 사라집니다."
        )

        if let changedCanvas = rasterizedScreenshot(from: canvas, in: app),
           let beforeCanvas = baselineCanvas,
           let diff = pixelDifferenceRatio(beforeCanvas, changedCanvas) {
            XCTAssertGreaterThan(
                diff,
                Self.motionTolerance,
                "\(sampleID)에서 offset override가 렌더에 적용되지 않습니다."
            )
        }

        closeSampleDetail(in: app)
    }

    @MainActor
    func testNodeControlInteractivityForEachSample() {
        let app = launchApp()
        for sampleID in Self.nodeControlCanvases {
            XCTContext.runActivity(named: "node-control-\(sampleID)") { _ in
                assertNodeControlsAreInteractive(for: sampleID, in: app)
            }
        }
    }

    @MainActor
    func testNodeOverrides_changeRenderingForEachSample() {
        let app = launchApp()
        for sampleID in Self.nodeControlCanvases {
            XCTContext.runActivity(named: "node-override-render-\(sampleID)") { _ in
                assertNodeOverrideChangesCanvas(for: sampleID, in: app)
            }
        }
    }
}
