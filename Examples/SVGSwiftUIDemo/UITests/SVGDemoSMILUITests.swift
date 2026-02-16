import Foundation
import UIKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest

extension SVGSwiftUIDemoUITests {
    @MainActor
    func testSmilTab_canSwitchAndRenderSamples() {
        let app = launchApp()
        XCTAssertTrue(
            selectDemoCatalogTab("demo.tab.smil", fallbackLabel: "SMIL", in: app),
            "SMIL 탭으로 전환되지 않았습니다."
        )
        XCTAssertTrue(
            waitForIdentifier("demo.content.smil", in: app, timeout: 3),
            "SMIL 탭의 목록 컨테이너가 표시되지 않았습니다."
        )

        for sampleID in Self.smilCanvases {
            assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: sampleID, in: app)
        }
    }

    @MainActor
    func testSmilAnimations_startStopAndKeyframeProgression() {
        let app = launchApp()
        XCTAssertTrue(
            selectDemoCatalogTab("demo.tab.smil", fallbackLabel: "SMIL", in: app),
            "SMIL 탭으로 전환되지 않았습니다."
        )

        for sampleID in Self.smilCanvases {
            XCTContext.runActivity(named: "smil-lifecycle-\(sampleID)") { _ in
                assertAnimationToggleFunctions(for: sampleID, in: app)
                assertSmilAnimationShowsKeyframeProgress(sampleID: sampleID, in: app)
            }
        }
    }

    @MainActor
    func assertSmilAnimationShowsKeyframeProgress(
        sampleID: String,
        in app: XCUIApplication
    ) {
        guard openSample(sampleID: sampleID, in: app) else {
            XCTFail("샘플 상세 화면으로 이동하지 못했습니다: \(sampleID)")
            return
        }
        let animationToggle = app.switches["demo.animationToggle.\(sampleID)"]
        XCTAssertTrue(animationToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(animationToggle.isHittable)

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
        scrollToIfNeeded(canvas, in: app, container: detailContainer)

        if boolValue(from: animationToggle) == false {
            animationToggle.tap()
            XCTAssertTrue(waitForToggleValue(animationToggle, expected: true))
        }

        guard let frame0 = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("초기 캔버스 스크린샷을 캡처하지 못했습니다: \(sampleID)")
            closeSampleDetail(in: app)
            return
        }

        var frames: [RasterImage] = [frame0]
        for _ in 0..<5 {
            XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 0.6))
            guard let nextFrame = rasterizedScreenshot(from: canvas, in: app) else {
                XCTFail("SMIL 키프레임 캡처에 실패했습니다: \(sampleID)")
                closeSampleDetail(in: app)
                return
            }
            frames.append(nextFrame)
        }

        var changedFrames = 0
        for index in 1..<frames.count {
            guard let diff = pixelDifferenceRatio(frames[0], frames[index]) else {
                XCTFail("픽셀 차이 계산 실패: \(sampleID), frame \(index)")
                closeSampleDetail(in: app)
                return
            }
            if diff > Self.motionTolerance * 2 {
                changedFrames += 1
            }
        }

        XCTAssertGreaterThan(
            changedFrames,
            1,
            "\(sampleID) 샘플에서 키프레임 진행에 따른 캔버스 변화가 충분하지 않습니다."
        )

        animationToggle.tap()
        _ = waitForToggleValue(animationToggle, expected: false, timeout: 2.0)
        XCTAssertTrue(
            isCanvasMostlyStable(
                canvas,
                in: app,
                timeout: 2.4,
                movementTolerance: Self.motionTolerance * 4,
                sampleInterval: 0.2,
                requiredStableSamples: 2
            ),
            "\(sampleID) 샘플에서 애니메이션 OFF 후 프레임 정지 동작이 불안정합니다."
        )

        closeSampleDetail(in: app)
    }
}
