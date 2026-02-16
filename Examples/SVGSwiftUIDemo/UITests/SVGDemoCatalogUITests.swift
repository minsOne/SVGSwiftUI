import Foundation
import UIKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest

extension SVGSwiftUIDemoUITests {
    @MainActor
    func testDemoSamples_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()

        for sampleID in Self.requiredCanvases {
            XCTContext.runActivity(named: "baseline-sample-\(sampleID)") { _ in
                assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: sampleID, in: app)
            }
        }
    }

    @MainActor
    func testDemoTabs_canSwitchToAnimationAndRemoteAndRenderValidation() {
        let app = launchApp()

        XCTAssertTrue(
            selectDemoCatalogTab("demo.tab.animation", fallbackLabel: "애니메이션", in: app),
            "애니메이션 탭으로 전환되지 않았습니다."
        )
        XCTAssertTrue(
            waitForIdentifier("demo.content.animation", in: app, timeout: 4),
            "애니메이션 탭의 목록 컨테이너가 표시되지 않았습니다."
        )

        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "animation-pulse", in: app)

        XCTAssertTrue(
            selectDemoCatalogTab("demo.tab.remote", fallbackLabel: "원격 SVG", in: app),
            "원격 SVG 탭으로 전환되지 않았습니다."
        )
        let urlField = app.textFields["demo.remote.urlField"]
        XCTAssertTrue(urlField.waitForExistence(timeout: 3))

        urlField.tap()
        urlField.typeText("bad url")
        app.buttons["demo.remote.loadButton"].tap()
        XCTAssertTrue(
            app.staticTexts["demo.remote.error"].waitForExistence(timeout: 2),
            "원격 SVG 탭에서 잘못된 URL 입력 시 에러 메시지가 노출되지 않았습니다."
        )

        XCTAssertTrue(
            selectDemoCatalogTab("demo.tab.w3c", fallbackLabel: "W3C 케이스", in: app),
            "W3C 탭으로 전환되지 않았습니다."
        )
        XCTAssertTrue(
            waitForIdentifier("demo.content.w3c", in: app, timeout: 3),
            "W3C 탭의 목록 컨테이너가 표시되지 않았습니다."
        )

        XCTAssertTrue(
            selectDemoCatalogTab("demo.tab.smil", fallbackLabel: "SMIL", in: app),
            "SMIL 탭으로 전환되지 않았습니다."
        )
        XCTAssertTrue(
            waitForIdentifier("demo.content.smil", in: app, timeout: 3),
            "SMIL 탭의 목록 컨테이너가 표시되지 않았습니다."
        )
    }

    @MainActor
    func testInlineCodeCanBeExpanded() {
        let app = launchApp()
        let sampleID = "animation-pulse"
        guard openSample(sampleID: sampleID, in: app) else {
            XCTFail("샘플 상세 화면으로 이동하지 못했습니다: \(sampleID)")
            return
        }
        let pulseCodeButton = app.buttons["demo.codeDisclosure.animation-pulse"]
        XCTAssertTrue(pulseCodeButton.waitForExistence(timeout: 5))
        pulseCodeButton.tap()

        let sampleCode = sourceElement(sampleID: sampleID, in: app)
        XCTAssertTrue(sampleCode.waitForExistence(timeout: 5))

        if sampleCode.waitForExistence(timeout: 1) {
            let firstLineContains = sampleCode.label.contains("<svg")
            XCTAssertTrue(firstLineContains)
        }
        closeSampleDetail(in: app)
    }
}
