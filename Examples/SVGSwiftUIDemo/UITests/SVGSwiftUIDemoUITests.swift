import Foundation
import UIKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest

final class SVGSwiftUIDemoUITests: XCTestCase {
    private static let requiredCanvases: [String] = [
        "badge",
        "panel",
        "route",
        "mesh-network",
        "spiral-paths",
        "aurora-wave",
        "dense-grid-world",
        "polyline-ribbon",
        "constellation-grid",
        "transform-radial-spiral",
        "path-commands",
        "polygon-polyline",
        "animation-pulse",
        "animation-drift",
        "animation-luminous-core",
        "animation-opacity-pulse",
        "animation-badge-breath",
        "animation-route-flow",
        "animation-geometry-fade",
        "animation-panel-bounce",
        "animation-style-sheet-fade",
        "animation-polygon-pulse",
        "animation-aurora-wisp",
        "animation-nested-drift",
        "animation-transform-radiant",
        "animation-smil-orbit-lumen",
        "animation-smil-breath-grid",
        "animation-smil-wave-shimmer",
        "geometry",
        "style-inline",
        "style-sheet",
        "orbital-lattice",
        "nested-groups"
    ]

    private static let animatedCanvases: [String] = [
        "animation-pulse",
        "animation-drift",
        "animation-luminous-core",
        "animation-opacity-pulse",
        "animation-badge-breath",
        "animation-route-flow",
        "animation-geometry-fade",
        "animation-panel-bounce",
        "animation-style-sheet-fade",
        "animation-polygon-pulse",
        "animation-aurora-wisp",
        "animation-nested-drift",
        "animation-transform-radiant",
        "animation-smil-orbit-lumen",
        "animation-smil-breath-grid",
        "animation-smil-wave-shimmer",
        "animation-smil-orbital",
        "animation-smil-drift-lines",
        "animation-smil-opacity-breath",
        "animation-smil-radar-spin",
        "animation-smil-mosaic-grid",
        "animation-smil-path-signal",
        "animation-smil-pulse-sunburst",
        "animation-smil-spin-petal",
        "animation-smil-color-lattice",
        "animation-smil-pendulum-sweep",
        "animation-smil-wave-cascade",
        "animation-smil-orbit-multi-ring"
    ]

    private static let nodeControlCanvases: [String] = requiredCanvases

    private static let renderSettleTimeout: TimeInterval = 2.0
    private static let renderSettleInterval: TimeInterval = 0.2
    private static let motionTolerance: Double = 0.0002
    private static let controlEnablePollTimeout: TimeInterval = 2.0

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDemoSample_badge_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "badge", in: app)
    }

    @MainActor
    func testDemoSample_panel_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "panel", in: app)
    }

    @MainActor
    func testDemoSample_route_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "route", in: app)
    }

    @MainActor
    func testDemoSample_mesh_network_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "mesh-network", in: app)
    }

    @MainActor
    func testDemoSample_spiral_paths_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "spiral-paths", in: app)
    }

    @MainActor
    func testDemoSample_aurora_wave_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "aurora-wave", in: app)
    }

    @MainActor
    func testDemoSample_dense_grid_world_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "dense-grid-world", in: app)
    }

    @MainActor
    func testDemoSample_polyline_ribbon_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "polyline-ribbon", in: app)
    }

    @MainActor
    func testDemoSample_constellation_grid_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "constellation-grid", in: app)
    }

    @MainActor
    func testDemoSample_transform_radial_spiral_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "transform-radial-spiral", in: app)
    }

    @MainActor
    func testDemoSample_path_commands_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "path-commands", in: app)
    }

    @MainActor
    func testDemoSample_polygon_polyline_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "polygon-polyline", in: app)
    }

    @MainActor
    func testDemoSample_animation_pulse_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "animation-pulse", in: app)
    }

    @MainActor
    func testDemoSample_animation_drift_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "animation-drift", in: app)
    }

    @MainActor
    func testDemoSample_animation_luminous_core_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "animation-luminous-core", in: app)
    }

    @MainActor
    func testDemoSample_geometry_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "geometry", in: app)
    }

    @MainActor
    func testDemoSample_style_inline_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "style-inline", in: app)
    }

    @MainActor
    func testDemoSample_style_sheet_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "style-sheet", in: app)
    }

    @MainActor
    func testDemoSample_orbital_lattice_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "orbital-lattice", in: app)
    }

    @MainActor
    func testDemoSample_nested_groups_canOpenAndRenderWithoutInvalidOverlay() {
        let app = launchApp()
        assertSampleCanOpenAndRenderWithoutInvalidOverlay(sampleID: "nested-groups", in: app)
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
    }

    @MainActor
    private func assertSampleCanOpenAndRenderWithoutInvalidOverlay(
        sampleID: String,
        in app: XCUIApplication
    ) {
        guard openSample(sampleID: sampleID, in: app) else {
            XCTFail("샘플 상세 화면으로 이동하지 못했습니다: \(sampleID)")
            return
        }
        defer {
            closeSampleDetail(in: app)
        }

        let detailContainer = discoverScrollableContainer(in: app)
        let canvasIdentifier = "demo.canvas.\(sampleID)"
        guard let canvasElement = discoverElement(
            identifier: canvasIdentifier,
            in: app,
            container: detailContainer,
            timeout: 8
        ) else {
            XCTFail("캔버스를 찾을 수 없습니다: \(canvasIdentifier)")
            return
        }

        scrollToIfNeeded(canvasElement, in: app, container: detailContainer)
        let invalid = canvasElement.descendants(
            matching: XCUIElement.ElementType.staticText
        ).matching(
            NSPredicate(format: "label IN %@", ["Invalid SVG", "invaildSVGRoot"])
        ).firstMatch

        if invalid.exists {
            let failureMessages = canvasElement
                .descendants(matching: XCUIElement.ElementType.staticText)
                .allElementsBoundByIndex
                .compactMap { $0.label.isEmpty ? nil : $0.label }
                .joined(separator: " | ")
            attachAccessibilityTreeSnapshot(
                in: app,
                context: "invalid_svg_overlay_\(sampleID)"
            )
            XCTFail(
                "샘플 렌더링 실패(Invalid SVG 오버레이): \(canvasIdentifier) / overlay: \(failureMessages)"
            )
        }
    }

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

    @MainActor
    func testCanvasMatchesBrowserBaselines() throws {
        continueAfterFailure = true
        let app = launchApp()
        let browserBaselineCases = try loadBrowserBaselineCases()
        let snapshotMode = SnapshotMode.current(sourceFilePath: #filePath)
        let referenceDirectory = browserReferenceDirectory()
        let shouldUseBrowserReference = referenceDirectory != nil
        let fileManager = FileManager.default
        let requiredSampleSet = Set(Self.requiredCanvases)
        let baselineSampleSet = Set(browserBaselineCases.map(\.sampleID))
        let missingBaselineSamples = requiredSampleSet.subtracting(baselineSampleSet)
        if !missingBaselineSamples.isEmpty {
            let missingList = missingBaselineSamples.sorted().joined(separator: ", ")
            XCTFail("브라우저 기준 비교 매핑 누락: \(missingList)")
        }

        if !shouldUseBrowserReference {
            let localDirectory = localBaselineDirectory()
            let hasLocalBaselines = browserBaselineCases.allSatisfy { caseItem in
                let baselineURL = localDirectory.appendingPathComponent("\(caseItem.baselineName).png")
                return fileManager.fileExists(atPath: baselineURL.path)
            }
            if !hasLocalBaselines && snapshotMode != .record {
                throw XCTSkip(
                    "Browser 기준 baseline 경로가 없어 비교를 진행할 수 없습니다. " +
                    "CI/로컬 검증 시 SVG_BROWSER_REFERENCE_DIR를 설정하고 테스트를 실행하세요."
                )
            }
        }

        let comparisonTolerance = browserImageTolerance()
        let mismatchTolerance = browserMismatchTolerance()
        for baselineCase in browserBaselineCases {
            let sampleID = baselineCase.sampleID
            guard openSample(sampleID: sampleID, in: app) else {
                XCTFail("샘플 상세 화면으로 이동하지 못했습니다: \(sampleID)")
                continue
            }
            let detailContainer = discoverScrollableContainer(in: app)
            let canvasIdentifier = "demo.canvas.\(sampleID)"
            guard let canvas = discoverElement(
                identifier: canvasIdentifier,
                in: app,
                container: detailContainer,
                timeout: 5
            ) else {
                XCTFail("Canvas를 찾지 못했습니다: \(canvasIdentifier)")
                attachAccessibilityTreeSnapshot(
                    in: app,
                context: "missing canvas: \(canvasIdentifier)"
            )
                closeSampleDetail(in: app)
                continue
            }
            XCTAssertTrue(canvas.waitForExistence(timeout: 1))
            scrollToIfNeeded(canvas, in: app, container: detailContainer)
            ensureAnimationDisabledForSample(sampleID, in: app)
            waitForRenderSettled()

            let snapshotComparator = SnapshotComparator(
                mode: snapshotMode,
                tolerance: mismatchTolerance,
                comparisonTolerance: comparisonTolerance,
                referenceDirectory: referenceDirectory,
                useBrowserReference: shouldUseBrowserReference
            )
            guard let canvasImage = rasterizedScreenshot(from: canvas, in: app) else {
                XCTFail("캔버스 캡처를 할 수 없습니다: \(canvasIdentifier)")
                attachAccessibilityTreeSnapshot(
                    in: app,
                    context: "capture-failed: \(canvasIdentifier)"
                )
                closeSampleDetail(in: app)
                continue
            }
            snapshotComparator.assertMatchesBaseline(
                rasterImage: canvasImage,
                baselineName: baselineCase.baselineName,
                sourceFilePath: #filePath,
                compareTargetSize: baselineCase.expectedSize
            )
            closeSampleDetail(in: app)
        }
    }

    @MainActor
    func testBrowserOracleManifestCoversDemoSamples() throws {
        let manifestCases = try loadBrowserBaselineCases()
        let requiredSampleSet = Set(Self.requiredCanvases + Self.animatedCanvases)
        let manifestSampleSet = Set(manifestCases.map(\.sampleID))
        let duplicateSampleCases = Dictionary(grouping: manifestCases, by: \.sampleID)
            .filter { $0.value.count > 1 }

        if !duplicateSampleCases.isEmpty {
            let duplicatedSamples = duplicateSampleCases.keys
                .sorted()
                .joined(separator: ", ")
            XCTFail("브라우저 오라클 manifest에 중복 샘플이 있습니다: \(duplicatedSamples)")
        }

        let missingSourceFiles = manifestCases.filter { caseItem in
            let sourceFileURL = URL(fileURLWithPath: caseItem.sourceSVGPath)
            return !FileManager.default.fileExists(atPath: sourceFileURL.path)
        }
        if !missingSourceFiles.isEmpty {
            let firstMissing = missingSourceFiles.first?.sourceSVGPath ?? ""
            XCTFail("브라우저 오라클 manifest의 SVG 경로 중 존재하지 않는 파일이 있습니다: \(firstMissing)")
        }

        XCTAssertEqual(
            manifestSampleSet,
            requiredSampleSet,
            "브라우저 오라클 manifest 샘플과 requiredCanvases가 일치하지 않습니다."
        )
    }

    @MainActor
    private func assertAnimationToggleFunctions(for sampleID: String, in app: XCUIApplication) {
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

        let initialState = boolValue(from: animationToggle)
        XCTAssertNotNil(initialState, "애니메이션 토글 상태를 읽을 수 없습니다: \(sampleID)")
        let isInitiallyOn = initialState ?? false
        if isInitiallyOn {
            animationToggle.tap()
            let _ = waitForToggleValue(animationToggle, expected: false)
            _ = waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.8)
            XCTAssertTrue(
                isCanvasMostlyStable(
                    canvas,
                    in: app,
                    timeout: 2.4,
                    movementTolerance: Self.motionTolerance * 3,
                    sampleInterval: 0.2,
                    requiredStableSamples: 3
                ),
                "\(sampleID) 샘플에서 애니메이션 OFF 전환 후에도 캔버스가 변화합니다."
            )
        } else {
            XCTAssertTrue(
                isCanvasMostlyStable(
                    canvas,
                    in: app,
                    timeout: 1.2,
                    movementTolerance: Self.motionTolerance * 2,
                    sampleInterval: 0.2,
                    requiredStableSamples: 3
                ),
                "\(sampleID) 샘플에서 애니메이션 OFF 상태에서 이미 정적이지 않습니다."
            )
        }

        animationToggle.tap()
        let _ = waitForToggleValue(animationToggle, expected: true)
        _ = waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 2.0)
        XCTAssertTrue(
            canvasHasVisualMovement(canvas, in: app),
            "\(sampleID) 샘플에서 애니메이션 ON 전환 후 캔버스 변화가 감지되지 않습니다."
        )
        closeSampleDetail(in: app)
    }

    @MainActor
    private func assertNodeControlsAreInteractive(
        for sampleID: String,
        in app: XCUIApplication
    ) {
        guard openSample(sampleID: sampleID, in: app) else {
            XCTFail("샘플 상세 화면으로 이동하지 못했습니다: \(sampleID)")
            return
        }

        let detailContainer = discoverScrollableContainer(in: app)
        let overrideToggle = app.switches["demo.nodeOverrideEnabled.\(sampleID)"]
        let scaleSliderID = "demo.nodeScale.\(sampleID)"
        let offsetXSliderID = "demo.nodeOffsetX.\(sampleID)"
        let offsetYSliderID = "demo.nodeOffsetY.\(sampleID)"
        let opacitySliderID = "demo.nodeOpacity.\(sampleID)"
        let canvasID = "demo.canvas.\(sampleID)"
        let fillOptionRed = app.buttons["demo.nodeFillOption.\(sampleID).red"]
        let strokeOptionBlue = app.buttons["demo.nodeStrokeOption.\(sampleID).blue"]
        let targetPicker = app.buttons["demo.nodeTargetPicker.\(sampleID)"]

        XCTAssertTrue(overrideToggle.waitForExistence(timeout: 5))
        guard let canvas = discoverElement(identifier: canvasID, in: app, container: detailContainer, timeout: 5) else {
            XCTFail("Canvas를 찾지 못했습니다: \(canvasID)")
            closeSampleDetail(in: app)
            return
        }

        let scaleSlider = app.sliders[scaleSliderID]
        let offsetXSlider = app.sliders[offsetXSliderID]
        let offsetYSlider = app.sliders[offsetYSliderID]
        let opacitySlider = app.sliders[opacitySliderID]
        XCTAssertTrue(scaleSlider.waitForExistence(timeout: 5))
        XCTAssertTrue(offsetXSlider.waitForExistence(timeout: 5))
        XCTAssertTrue(offsetYSlider.waitForExistence(timeout: 5))
        XCTAssertTrue(opacitySlider.waitForExistence(timeout: 5))
        XCTAssertFalse(scaleSlider.isEnabled)
        XCTAssertFalse(offsetXSlider.isEnabled)
        XCTAssertFalse(offsetYSlider.isEnabled)
        XCTAssertFalse(opacitySlider.isEnabled)

        overrideToggle.tap()
        XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.4))
        XCTAssertTrue(
            waitForEnabled(scaleSlider, timeout: Self.controlEnablePollTimeout),
            "\(sampleID) 샘플에서 scale slider가 활성화되지 않습니다."
        )
        XCTAssertTrue(
            waitForEnabled(offsetXSlider, timeout: Self.controlEnablePollTimeout),
            "\(sampleID) 샘플에서 offsetX slider가 활성화되지 않습니다."
        )
        XCTAssertTrue(
            waitForEnabled(offsetYSlider, timeout: Self.controlEnablePollTimeout),
            "\(sampleID) 샘플에서 offsetY slider가 활성화되지 않습니다."
        )
        XCTAssertTrue(
            waitForEnabled(opacitySlider, timeout: Self.controlEnablePollTimeout),
            "\(sampleID) 샘플에서 opacity slider가 활성화되지 않습니다."
        )

        guard let baselineCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("초기 캔버스 스크린샷을 캡처하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-check-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }

        offsetXSlider.adjust(toNormalizedSliderPosition: 0.35)
        XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.0))
        guard let offsetXCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("offsetX 조작 후 캔버스 스크린샷을 캡처하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-offsetx-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        guard let offsetXDiff = pixelDifferenceRatio(baselineCanvas, offsetXCanvas) else {
            XCTFail("offsetX 조작 전/후 픽셀 비교를 계산하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-offsetx-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        XCTAssertGreaterThan(offsetXDiff, Self.motionTolerance, "\(sampleID) 샘플에서 offsetX 슬라이더가 동작하지 않습니다.")

        guard let beforeScaleCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("offsetX 반응 후 캔버스 캡처에 실패했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-scale-before-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        scaleSlider.adjust(toNormalizedSliderPosition: 0.85)
        XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.0))
        guard let afterScaleCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("scale 조작 후 캔버스 스크린샷을 캡처하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-scale-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        guard let scaleDiff = pixelDifferenceRatio(beforeScaleCanvas, afterScaleCanvas) else {
            XCTFail("scale 조작 전/후 픽셀 비교를 계산하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-scale-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        XCTAssertGreaterThan(scaleDiff, Self.motionTolerance, "\(sampleID) 샘플에서 scale 슬라이더가 동작하지 않습니다.")

        guard let beforeOpacityCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("scale 반응 후 캔버스 캡처에 실패했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-opacity-before-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        opacitySlider.adjust(toNormalizedSliderPosition: 0.55)
        waitForRenderSettled()
        guard let afterOpacityCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("opacity 조작 후 캔버스 스크린샷을 캡처하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-opacity-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        guard let opacityDiff = pixelDifferenceRatio(beforeOpacityCanvas, afterOpacityCanvas) else {
            XCTFail("opacity 조작 전/후 픽셀 비교를 계산하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-opacity-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        XCTAssertGreaterThan(opacityDiff, Self.motionTolerance, "\(sampleID) 샘플에서 opacity 슬라이더가 동작하지 않습니다.")

        // offsetY 값 변경도 최소 1회 확인하여 노드 오버라이드 이동 제어가 적용되는지 점검한다.
        guard let beforeOffsetYCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("scale/opacity 후 캔버스 캡처에 실패했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-offsety-before-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        offsetYSlider.adjust(toNormalizedSliderPosition: 0.65)
        XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.0))
        guard let afterOffsetYCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("offsetY 조작 후 캔버스 스크린샷을 캡처하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-offsety-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        guard let offsetYDiff = pixelDifferenceRatio(beforeOffsetYCanvas, afterOffsetYCanvas) else {
            XCTFail("offsetY 조작 전/후 픽셀 비교를 계산하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-offsety-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        XCTAssertGreaterThan(offsetYDiff, Self.motionTolerance, "\(sampleID) 샘플에서 offsetY 슬라이더가 동작하지 않습니다.")

        // 색상 세그먼트는 캔버스 변화로 추가 검증한다.
        guard let beforeFillCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("색상 변경 전 캔버스 캡처에 실패했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-fill-before-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }

        XCTAssertTrue(fillOptionRed.waitForExistence(timeout: 5))
        fillOptionRed.tap()
        waitForRenderSettled()
        XCTAssertTrue(strokeOptionBlue.waitForExistence(timeout: 5))
        strokeOptionBlue.tap()
        waitForRenderSettled()
        guard let afterColorCanvas = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("색상 변경 후 캔버스 스크린샷을 캡처하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-color-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        guard let colorDiff = pixelDifferenceRatio(beforeFillCanvas, afterColorCanvas) else {
            XCTFail("색상 변경 전/후 픽셀 비교를 계산하지 못했습니다.")
            attachAccessibilityTreeSnapshot(in: app, context: "interactivity-color-\(sampleID)")
            closeSampleDetail(in: app)
            return
        }
        XCTAssertGreaterThan(colorDiff, Self.motionTolerance, "\(sampleID) 샘플에서 색상 제어가 렌더링에 반영되지 않습니다.")

        if targetPicker.waitForExistence(timeout: 2) && targetPicker.isHittable {
            targetPicker.tap()

            let targetOptionQuery = app.buttons.matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@",
                    "demo.nodeTargetOption.\(sampleID)."
                )
            )
            if targetOptionQuery.count > 1 {
                targetOptionQuery.element(boundBy: 1).tap()
                XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.0))
            } else if targetOptionQuery.count == 1 {
                targetOptionQuery.element(boundBy: 0).tap()
                XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.0))
            }
        }

        if let canvas = discoverElement(
            identifier: "demo.canvas.\(sampleID)",
            in: app,
            container: detailContainer,
            timeout: 3
        ) {
            scrollToIfNeeded(canvas, in: app, container: detailContainer)
        }
        closeSampleDetail(in: app)
    }

    @MainActor
    private func ensureAnimationDisabledForSample(_ sampleID: String, in app: XCUIApplication) {
        let animationToggle = app.switches["demo.animationToggle.\(sampleID)"]
        if !animationToggle.exists {
            return
        }

        guard boolValue(from: animationToggle) == true else {
            return
        }
        animationToggle.tap()
        _ = waitForToggleValue(animationToggle, expected: false, timeout: 2.0)
    }

    @MainActor
    private func assertNodeOverrideChangesCanvas(
        for sampleID: String,
        in app: XCUIApplication
    ) {
        guard openSample(sampleID: sampleID, in: app) else {
            XCTFail("샘플 상세 화면으로 이동하지 못했습니다: \(sampleID)")
            return
        }
        let detailContainer = discoverScrollableContainer(in: app)
        guard let canvas = discoverElement(
            identifier: "demo.canvas.\(sampleID)",
            in: app,
            container: detailContainer,
            timeout: 5
        ) else {
            attachAccessibilityTreeSnapshot(
                in: app,
                context: "missing canvas: \(sampleID)"
            )
            XCTFail("Canvas를 찾지 못했습니다: demo.canvas.\(sampleID)")
            closeSampleDetail(in: app)
            return
        }

        let overrideToggle = app.switches["demo.nodeOverrideEnabled.\(sampleID)"]
        let scaleSlider = app.sliders["demo.nodeScale.\(sampleID)"]

        scrollToIfNeeded(canvas, in: app, container: detailContainer)
        XCTAssertTrue(overrideToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(scaleSlider.waitForExistence(timeout: 5))
        XCTAssertFalse(scaleSlider.isEnabled)

        guard let baselineScreenshot = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("초기 캔버스 스크린샷을 캡처하지 못했습니다.")
            closeSampleDetail(in: app)
            return
        }

        overrideToggle.tap()
        XCTAssertTrue(waitForCanvasToSettle(canvas: canvas, in: app))
        XCTAssertTrue(
            waitForEnabled(scaleSlider, timeout: Self.controlEnablePollTimeout),
            "\(sampleID) 샘플에서 노드 오버라이드 ON 후 scale slider가 활성화되지 않습니다."
        )
        scaleSlider.adjust(toNormalizedSliderPosition: 0.80)
        XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.0))

        guard let overrideEnabledScreenshot = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("노드 오버라이드 ON 시 스크린샷 캡처 실패")
            closeSampleDetail(in: app)
            return
        }

        let enabledRatio = pixelDifferenceRatio(
            baselineScreenshot,
            overrideEnabledScreenshot
        )
        XCTAssertNotNil(enabledRatio)
        if let enabledRatio {
            XCTAssertGreaterThan(
                enabledRatio,
                Self.motionTolerance,
                "\(sampleID) 샘플에서 노드 오버라이드 ON/OFF 픽셀 차이 값이 너무 작습니다."
            )
        }

        guard let beforeAdjustmentScreenshot = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("스케일 조정 전 스크린샷 캡처 실패")
            closeSampleDetail(in: app)
            return
        }
        scaleSlider.adjust(toNormalizedSliderPosition: 0.20)
        XCTAssertTrue(waitForRenderSettledAndCapture(canvas: canvas, in: app, timeout: 1.0))

        guard let afterAdjustmentScreenshot = rasterizedScreenshot(from: canvas, in: app) else {
            XCTFail("스케일 조정 후 스크린샷 캡처 실패")
            closeSampleDetail(in: app)
            return
        }
        let adjustedRatio = pixelDifferenceRatio(beforeAdjustmentScreenshot, afterAdjustmentScreenshot)
        XCTAssertNotNil(adjustedRatio)
        if let adjustedRatio {
            XCTAssertGreaterThan(
                adjustedRatio,
                Self.motionTolerance,
                "\(sampleID) 샘플에서 스케일 조정 반영 픽셀 차이 값이 너무 작습니다."
            )
        }

        overrideToggle.tap()
        XCTAssertTrue(waitForCanvasToSettle(canvas: canvas, in: app))
        XCTAssertTrue(
            waitUntilDisabled(scaleSlider, timeout: Self.controlEnablePollTimeout),
            "\(sampleID) 샘플에서 노드 오버라이드 OFF 후 scale slider가 비활성화되지 않습니다."
        )

        closeSampleDetail(in: app)
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        if isCaptureDebugEnabled() {
            app.launchArguments.append("SVG_UI_CAPTURE_DEBUG")
        }
        app.launch()
        return app
    }

    private func isCaptureDebugEnabled() -> Bool {
        if ProcessInfo.processInfo.environment["SVG_UI_CAPTURE_DEBUG"] != nil {
            return true
        }
        if ProcessInfo.processInfo.arguments.contains("SVG_UI_CAPTURE_DEBUG") {
            return true
        }
        return true
    }

    @MainActor
    private func openSample(sampleID: String, in app: XCUIApplication) -> Bool {
        let sampleRowID = "demo.sampleRow.\(sampleID)"
        let contentContainer = discoverScrollableContainer(in: app)
        guard let sampleRow = discoverElement(
            identifier: sampleRowID,
            in: app,
            container: contentContainer,
            timeout: 6
        ) else {
            attachAccessibilityTreeSnapshot(
                in: app,
                context: "unable_to_find_sample_row_\(sampleID)"
            )
            return false
        }

        let isDetailVisible = app.descendants(matching: .any).matching(identifier: "demo.sampleDetail.\(sampleID)").element
        if isDetailVisible.exists {
            return isDetailVisible.waitForExistence(timeout: 1)
        }

        scrollToIfNeeded(sampleRow, in: app, container: contentContainer)
        sampleRow.tap()
        return isDetailVisible.waitForExistence(timeout: 5)
    }

    @MainActor
    private func closeSampleDetail(in app: XCUIApplication) {
        let rootContainer = app.otherElements["demo.content"]
        if rootContainer.exists {
            return
        }
        let animationRootContainer = app.otherElements["demo.content.animation"]
        if animationRootContainer.exists {
            return
        }
        let w3cRootContainer = app.otherElements["demo.content.w3c"]
        if w3cRootContainer.exists {
            return
        }
        let remoteRootContainer = app.otherElements["demo.content.remote"]
        if remoteRootContainer.exists {
            return
        }

        let fallbackRootContainer: XCUIElement = [
            rootContainer,
            animationRootContainer,
            w3cRootContainer,
            remoteRootContainer
        ].first(where: { $0.exists }) ?? rootContainer
        let backButton = app.navigationBars.buttons["SVGSwiftUI Demo"]
        if backButton.exists {
            backButton.tap()
            waitForRenderSettled()
            _ = fallbackRootContainer.waitForExistence(timeout: 4)
            return
        }

        let fallbackBackButton = app.navigationBars.buttons.element(boundBy: 0)
        if fallbackBackButton.exists && fallbackBackButton.isHittable {
            fallbackBackButton.tap()
            waitForRenderSettled()
        }
    }

    @MainActor
    private func selectDemoCatalogTab(
        _ identifier: String,
        fallbackLabel: String? = nil,
        in app: XCUIApplication
    ) -> Bool {
        let tabButton = app.tabBars.buttons[identifier]
        if tabButton.exists {
            tabButton.tap()
            return true
        }

        let identifierButtons = app.tabBars.buttons.matching(identifier: identifier)
        if identifierButtons.count > 0 {
            identifierButtons.element(boundBy: 0).tap()
            return true
        }

        let fallbackButton = app.buttons[identifier]
        if fallbackButton.exists {
            fallbackButton.tap()
            return true
        }

        if let fallbackLabel {
            let exactLabelButton = app.tabBars.buttons[fallbackLabel]
            if exactLabelButton.exists {
                exactLabelButton.tap()
                return true
            }

            let labelPredicate = NSPredicate(
                format: "label == %@ OR label CONTAINS %@",
                fallbackLabel,
                fallbackLabel
            )
            let candidateButtons = app.tabBars.buttons.matching(labelPredicate)
            if candidateButtons.count > 0 {
                candidateButtons.element(boundBy: 0).tap()
                return true
            }
        }

        return false
    }

    @MainActor
    private func scrollToIfNeeded(_ element: XCUIElement, in app: XCUIApplication, container: XCUIElement) {
        var attempts = 0
        while attempts < 12 {
            if element.exists && element.isHittable {
                return
            }

            scrollInContainer(container, app: app)
            attempts += 1
            waitForRenderSettled()

            if element.exists && element.isHittable {
                return
            }
        }

        if element.exists {
            return
        }

        XCTAssertTrue(element.exists)
    }

    @MainActor
    private func scrollInContainer(_ container: XCUIElement, app: XCUIApplication) {
        if container.exists && container.isHittable {
            container.swipeUp()
            return
        }

        let contentScrollView = app.scrollViews.firstMatch
        if contentScrollView.exists && contentScrollView.isHittable {
            contentScrollView.swipeUp()
            return
        }

        app.swipeUp()
    }

    @MainActor
    private func discoverScrollableContainer(in app: XCUIApplication) -> XCUIElement {
        let contentContainer = app.otherElements["demo.content"]
        if contentContainer.exists {
            return contentContainer
        }
        let animationContent = app.otherElements["demo.content.animation"]
        if animationContent.exists {
            return animationContent
        }
        let w3cContent = app.otherElements["demo.content.w3c"]
        if w3cContent.exists {
            return w3cContent
        }
        let remoteContent = app.otherElements["demo.content.remote"]
        if remoteContent.exists {
            return remoteContent
        }

        let firstScrollView = app.scrollViews.element(boundBy: 0)
        if firstScrollView.exists {
            return firstScrollView
        }

        let firstTable = app.tables.element(boundBy: 0)
        if firstTable.exists {
            return firstTable
        }

        return app.otherElements.firstMatch
    }

    @MainActor
    private func waitForIdentifier(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.1
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let match = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            if match.exists {
                return true
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }
        return false
    }

    @MainActor
    private func waitForRenderSettled() {
        Thread.sleep(forTimeInterval: Self.renderSettleInterval)
    }

    @discardableResult
    @MainActor
    private func waitForEnabled(
        _ element: XCUIElement,
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.1
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.isEnabled {
                return true
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }
        return false
    }

    @discardableResult
    @MainActor
    private func activateSwitch(
        _ control: XCUIElement,
        expected: Bool,
        timeout: TimeInterval = 2.0
    ) -> Bool {
        control.tap()
        if waitForToggleValue(control, expected: expected, timeout: timeout) {
            return true
        }

        let knob = control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        knob.tap()
        return waitForToggleValue(control, expected: expected, timeout: timeout)
    }

    @discardableResult
    @MainActor
    private func waitForToggleValue(
        _ control: XCUIElement,
        expected: Bool,
        timeout: TimeInterval = 2.0,
        pollInterval: TimeInterval = 0.1
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if boolValue(from: control) == expected {
                return true
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }
        return false
    }

    @discardableResult
    @MainActor
    private func waitUntilDisabled(
        _ element: XCUIElement,
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.1
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !element.isEnabled {
                return true
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }
        return false
    }

    @discardableResult
    @MainActor
    private func waitForRenderSettledAndCapture(
        canvas: XCUIElement,
        in app: XCUIApplication,
        timeout: TimeInterval = 2.0
    ) -> Bool {
        return waitForCanvasToSettle(canvas: canvas, in: app, timeout: timeout)
    }

    @discardableResult
    @MainActor
    private func waitForCanvasToSettle(
        canvas: XCUIElement,
        in app: XCUIApplication,
        timeout: TimeInterval = 2.0
    ) -> Bool {
        guard canvas.exists else {
            return false
        }

        guard var previousFrame = rasterizedScreenshot(from: canvas, in: app) else {
            return false
        }

        var stableFrameCount = 0
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
            guard let currentFrame = rasterizedScreenshot(from: canvas, in: app) else {
                return false
            }

            let diff = pixelDifferenceRatio(previousFrame, currentFrame) ?? 1.0
            if diff <= 0.0002 {
                stableFrameCount += 1
                if stableFrameCount >= 2 {
                    return true
                }
            } else {
                stableFrameCount = 0
            }

            previousFrame = currentFrame
        }

        return false
    }

    @MainActor
    private func isCanvasMostlyStable(
        _ canvas: XCUIElement,
        in app: XCUIApplication,
        timeout: TimeInterval = 1.2,
        movementTolerance: Double = 0.0002,
        sampleInterval: TimeInterval = 0.2,
        requiredStableSamples: Int = 2
    ) -> Bool {
        guard var previousFrame = rasterizedScreenshot(from: canvas, in: app) else {
            return false
        }

        var stableSamples = 0
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: sampleInterval)
            guard let currentFrame = rasterizedScreenshot(from: canvas, in: app) else {
                return false
            }

            guard let diff = pixelDifferenceRatio(previousFrame, currentFrame) else {
                return false
            }

            if diff <= movementTolerance {
                stableSamples += 1
                if stableSamples >= requiredStableSamples {
                    return true
                }
            } else {
                stableSamples = 0
            }

            previousFrame = currentFrame
        }

        return false
    }

    @MainActor
    private func canvasHasVisualMovement(
        _ canvas: XCUIElement,
        in app: XCUIApplication,
        timeout: TimeInterval = 1.2
    ) -> Bool {
        guard var previousFrame = rasterizedScreenshot(from: canvas, in: app) else {
            return false
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
            guard let currentFrame = rasterizedScreenshot(from: canvas, in: app) else {
                return false
            }
            if let diff = pixelDifferenceRatio(previousFrame, currentFrame),
               diff > Self.motionTolerance {
                return true
            }
            previousFrame = currentFrame
        }

        return false
    }

    @MainActor
    private func boolValue(from control: XCUIElement) -> Bool? {
        if let boolValue = control.value as? Bool {
            return boolValue
        }

        guard let rawValue = control.value as? String else {
            return nil
        }
        let normalizedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalizedValue {
        case "1", "true", "on", "yes", "enabled":
            return true
        case "0", "false", "off", "no", "disabled":
            return false
        default:
            return nil
        }
    }

    @MainActor
    private func discoverElement(
        identifier: String,
        in app: XCUIApplication,
        container: XCUIElement,
        timeout: TimeInterval
    ) -> XCUIElement? {
        let initialTimeout = min(timeout, 2.0)
        if uiElement(for: identifier, in: app).waitForExistence(timeout: initialTimeout) {
            return uiElement(for: identifier, in: app)
        }

        var attempts = 0
        while attempts < 12 {
            scrollInContainer(container, app: app)
            waitForRenderSettled()
            if uiElement(for: identifier, in: app).exists {
                return uiElement(for: identifier, in: app)
            }
            attempts += 1
        }

        return nil
    }

    @MainActor
    private func uiElement(for identifier: String, in app: XCUIApplication) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: identifier).element(boundBy: 0)
    }

    @MainActor
    private func sourceElement(
        sampleID: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        let identifier = "demo.source.\(sampleID)"
        let directMatch = app.descendants(matching: .any).matching(identifier: identifier).element(boundBy: 0)
        if directMatch.exists {
            return directMatch
        }

        let svgPredicate = NSPredicate(format: "label CONTAINS[c] '<svg'")
        let svgElement = app.descendants(matching: .staticText).matching(svgPredicate).element(boundBy: 0)
        if svgElement.exists {
            return svgElement
        }

        let identifierFallback = app.descendants(matching: .any).matching(identifier: identifier).element(boundBy: 0)
        return identifierFallback
    }

    @MainActor
    private func attachAccessibilityTreeSnapshot(in app: XCUIApplication, context: String) {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = "Accessibility tree: \(context)"
        XCTContext.runActivity(named: "Accessibility dump: \(context)") { activity in
            activity.add(attachment)
        }
    }

    private func browserReferenceDirectory() -> URL? {
        if let envValue = browserReferenceDirectoryFromEnvironment() {
            return envValue
        }
        return browserReferenceDirectoryFromDiscovery()
    }

    private func browserReferenceDirectoryFromEnvironment() -> URL? {
        guard let value = ProcessInfo.processInfo.environment["SVG_BROWSER_REFERENCE_DIR"],
              !value.isEmpty else {
            return nil
        }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            return nil
        }
        let candidateURL = URL(fileURLWithPath: trimmedValue, isDirectory: true)
        if isDirectoryExisting(path: candidateURL.path) {
            return candidateURL
        }
        return nil
    }

    private func browserReferenceDirectoryFromDiscovery() -> URL? {
        var candidateRoots = [URL]()
        let sourceFileURL = URL(fileURLWithPath: String(describing: #filePath))
        var scanningRoot = sourceFileURL.deletingLastPathComponent()
        for _ in 0..<12 {
            candidateRoots.append(scanningRoot)
            scanningRoot = scanningRoot.deletingLastPathComponent()
        }

        if let workspace = ProcessInfo.processInfo.environment["PROJECT_DIR"] {
            candidateRoots.append(URL(fileURLWithPath: workspace))
        }
        if let sourceRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
            candidateRoots.append(URL(fileURLWithPath: sourceRoot))
        }
        if let currentWorkingDirectory = ProcessInfo.processInfo.environment["PWD"] {
            candidateRoots.append(URL(fileURLWithPath: currentWorkingDirectory))
        }
        candidateRoots.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath))

        var seenRoots = Set<String>()
        for root in candidateRoots {
            let rootPath = root.standardized.path
            if seenRoots.contains(rootPath) {
                continue
            }
            seenRoots.insert(rootPath)
            let legacyPath = root
                .appendingPathComponent("Examples", isDirectory: true)
                .appendingPathComponent("SVGSwiftUIDemo", isDirectory: true)
                .appendingPathComponent("UITests", isDirectory: true)
                .appendingPathComponent("BrowserBaselines", isDirectory: true)
            if isDirectoryExisting(path: legacyPath.path) {
                return legacyPath
            }
        }

        return nil
    }

    private func isDirectoryExisting(path: String) -> Bool {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        guard let fileType = attributes?[.type] as? FileAttributeType else {
            return false
        }
        return fileType == .typeDirectory
    }

    private func browserImageTolerance() -> Double {
        let rawValue = ProcessInfo.processInfo.environment["SVG_BROWSER_REFERENCE_TOLERANCE"]
        guard let value = rawValue else {
            return 2.0
        }
        guard let parsed = Double(value), parsed.isFinite else {
            return 2.0
        }
        if parsed < 0.0 {
            return 0.0
        }
        return parsed
    }

    private func browserMismatchTolerance() -> Double {
        return 0.005
    }

    private func localBaselineDirectory() -> URL {
        let sourcePath = String(describing: #filePath)
        let sourceFileURL = URL(fileURLWithPath: sourcePath)
        let sourceDirectory = sourceFileURL.deletingLastPathComponent()
        let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "UnknownDevice"
        let runtimeVersion = ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_VERSION"] ?? "UnknownRuntime"
        let safeDeviceName = deviceName.fileSystemSafeString()
        let safeRuntimeVersion = runtimeVersion.fileSystemSafeString()
        return sourceDirectory
            .appendingPathComponent("Baselines", isDirectory: true)
            .appendingPathComponent(safeDeviceName, isDirectory: true)
            .appendingPathComponent(safeRuntimeVersion, isDirectory: true)
    }

    @MainActor
    private func rasterizedScreenshot(from element: XCUIElement, in app: XCUIApplication) -> RasterImage? {
        let shouldLogCapture = isCaptureDebugEnabled()
        guard element.exists else {
            if shouldLogCapture {
                let message = "rasterizedScreenshot(from:in:) - element not found: \(element.identifier)"
                print(message)
                appendCaptureDebugLog(message)
            }
            return nil
        }

        if let screenshot = rasterImage(from: element.screenshot()) {
            if shouldLogCapture {
                let message = String(
                    "element screenshot succeeded: element=\(element.identifier), " +
                        "elementFrame=\(element.frame), " +
                        "screenshot size=\(screenshot.width)x\(screenshot.height)"
                )
                print(message)
                appendCaptureDebugLog(message)
            }
            return screenshot
        }

        if let cropped = rasterizedScreenshot(from: element, appFallback: app) {
            if shouldLogCapture {
                let message = "fallback capture succeeded: element=\(element.identifier), elementFrame=\(element.frame)"
                print(message)
                appendCaptureDebugLog(message)
            }
            return cropped
        }
        if shouldLogCapture {
            appendCaptureDebugLog("fallback capture skipped: element=\(element.identifier)")
            appendCaptureDebugLog(
                "element.screenshot frame=\(element.frame), " +
                    "hittable=\(element.isHittable), enabled=\(element.isEnabled)"
            )
        }
        let screenshot = element.screenshot()
        if shouldLogCapture {
            if let raster = rasterImage(from: screenshot.pngRepresentation) {
                let message = "element.screenshot raster size=\(raster.width)x\(raster.height)"
                print(message)
                appendCaptureDebugLog(message)
            }
        }
        return rasterImage(from: screenshot)
    }

    @MainActor
    private func rasterizedScreenshot(from element: XCUIElement, appFallback app: XCUIApplication) -> RasterImage? {
        let fullWindow = app.windows.element(boundBy: 0)
        let shouldLogCapture = isCaptureDebugEnabled()
        if shouldLogCapture {
            let message = "window exists=\(fullWindow.exists), identifier=\(fullWindow.identifier), frame=\(fullWindow.frame)"
            print(message)
            appendCaptureDebugLog(message)
        }
        let usesWindowFallback = fullWindow.exists && fullWindow.frame.isValid()
        if !usesWindowFallback {
            if shouldLogCapture {
                let message = "window fallback unavailable"
                print(message)
                appendCaptureDebugLog(message)
            }
            return nil
        }

        let fullScreenshot = app.screenshot()
        guard let fullImage = rasterImage(from: fullScreenshot) else {
            if shouldLogCapture {
                let message = "full screenshot->raster conversion 실패"
                print(message)
                appendCaptureDebugLog(message)
            }
            return nil
        }
        if shouldLogCapture {
            let message = String(
                "full screenshot raster size=\(fullImage.width)x\(fullImage.height), " +
                    "window frame=\(fullWindow.frame)"
            )
            print(message)
            appendCaptureDebugLog(message)
        }

        let fullWindowFrame = fullWindow.frame
        let targetFrame = element.frame
        if shouldLogCapture {
            let message = "target frame for identifier=\(element.identifier): \(targetFrame)"
            print(message)
            appendCaptureDebugLog(message)
        }
        let intersects = fullWindowFrame.intersects(targetFrame)
        if !intersects || targetFrame.width <= 0 || targetFrame.height <= 0 {
            if shouldLogCapture {
                let message = "target frame does not intersect with window"
                print(message)
                appendCaptureDebugLog(message)
            }
            return nil
        }

        let scaleX = Double(fullImage.width) / Double(fullWindowFrame.width)
        let scaleY = Double(fullImage.height) / Double(fullWindowFrame.height)
        if !scaleX.isFinite || !scaleY.isFinite || scaleX <= 0 || scaleY <= 0 {
            let message = "invalid scale values: scaleX=\(scaleX), scaleY=\(scaleY), fullImage=\(fullImage.width)x\(fullImage.height), window=\(fullWindowFrame)"
            appendCaptureDebugLog(message)
            return nil
        }

        let x = Int((targetFrame.minX - fullWindowFrame.minX) * scaleX)
        let y = Int((targetFrame.minY - fullWindowFrame.minY) * scaleY)
        let width = Int(targetFrame.width * scaleX)
        let height = Int(targetFrame.height * scaleY)
        if shouldLogCapture {
            let message = String(
                "fallback geometry: targetFrame=\(targetFrame), fullImage=\(fullImage.width)x\(fullImage.height), " +
                    "scaleX=\(scaleX), scaleY=\(scaleY), x=\(x), y=\(y), w=\(width), h=\(height)"
            )
            print(message)
            appendCaptureDebugLog(message)
        }

        let sourceX = max(0, x)
        let sourceY = max(0, y)
        let sourceWidth = min(width, fullImage.width - sourceX)
        let sourceHeight = min(height, fullImage.height - sourceY)
        if shouldLogCapture {
            let message = String(
                "source rect before clamp: x=\(x), y=\(y), w=\(width), h=\(height), " +
                    "clampedRect=x:\(sourceX), y:\(sourceY), w:\(sourceWidth), h:\(sourceHeight)"
            )
            print(message)
            appendCaptureDebugLog(message)
        }
        if sourceWidth <= 0 || sourceHeight <= 0 {
            if shouldLogCapture {
                let message = "source width/height invalid; cannot crop"
                print(message)
                appendCaptureDebugLog(message)
            }
            return nil
        }

        return crop(rasterImage: fullImage, x: sourceX, y: sourceY, width: sourceWidth, height: sourceHeight)
    }

    private func appendCaptureDebugLog(_ message: String) {
        let debugDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let debugURL = debugDirectory.appendingPathComponent("SVG_UI_CAPTURE_DEBUG.log")
        let timestamp = Date()
            .timeIntervalSinceReferenceDate
            .description
        let log = "[\(timestamp)] \(message)\n"
        guard let logData = log.data(using: .utf8) else {
            return
        }
        if FileManager.default.fileExists(atPath: debugURL.path) {
            guard let output = try? FileHandle(forWritingTo: debugURL) else {
                return
            }
            defer {
                try? output.close()
            }
            output.seekToEndOfFile()
            try? output.write(contentsOf: logData)
            return
        }

        try? logData.write(to: debugURL, options: .atomic)
    }

    @MainActor
    private func rasterImage(from screenshot: XCUIScreenshot) -> RasterImage? {
        let data = screenshot.pngRepresentation
        let pngImage = rasterImage(from: data)
        return pngImage
    }

    private func rasterImage(from imageData: Data) -> RasterImage? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return rasterImage(from: cgImage)
    }

    private func crop(
        rasterImage: RasterImage,
        x: Int,
        y: Int,
        width: Int,
        height: Int
    ) -> RasterImage? {
        let sourceWidth = rasterImage.width
        let sourceHeight = rasterImage.height
        if sourceWidth <= 0 || sourceHeight <= 0 {
            return nil
        }
        let sourceRect = CGRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
        let clampedRect = sourceRect.intersection(
            CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight)
        )
        if clampedRect.isNull || !clampedRect.isValid() || clampedRect.width <= 0 || clampedRect.height <= 0 {
            return nil
        }

        let clampedX = Int(clampedRect.minX)
        let clampedY = Int(clampedRect.minY)
        let clampedWidth = Int(clampedRect.width)
        let clampedHeight = Int(clampedRect.height)

        var croppedData = [UInt8](repeating: 0, count: clampedWidth * clampedHeight * 4)
        let sourceStride = sourceWidth * 4
        let targetStride = clampedWidth * 4

        for row in 0..<clampedHeight {
            let sourceRowStart = (clampedY + row) * sourceStride + clampedX * 4
            let targetRowStart = row * targetStride
            let copyCount = clampedWidth * 4
            croppedData.withUnsafeMutableBytes { targetBuffer in
                rasterImage.bytes.withUnsafeBytes { sourceBuffer in
                    let sourcePointer = sourceBuffer.baseAddress!.advanced(by: sourceRowStart)
                    let targetPointer = targetBuffer.baseAddress!.advanced(by: targetRowStart)
                    targetPointer.copyMemory(from: sourcePointer, byteCount: copyCount)
                }
            }
        }

        return RasterImage(
            width: clampedWidth,
            height: clampedHeight,
            bytes: croppedData
        )
    }

    private func rasterImage(from cgImage: CGImage) -> RasterImage? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let imageByteCount = height * bytesPerRow
        if imageByteCount <= 0 {
            return nil
        }

        var pixelData = Data(count: imageByteCount)
        let conversionSucceeded = pixelData.withUnsafeMutableBytes { rawBytes -> Bool in
            guard let bufferPointer = rawBytes.bindMemory(to: UInt8.self).baseAddress else {
                return false
            }
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
                CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            )

            guard let context = CGContext(
                data: bufferPointer,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                return false
            }

            let drawRect = CGRect(
                x: 0.0,
                y: 0.0,
                width: CGFloat(width),
                height: CGFloat(height)
            )
            context.draw(cgImage, in: drawRect)
            return true
        }

        if !conversionSucceeded {
            return nil
        }

        return RasterImage(
            width: width,
            height: height,
            bytes: Array(pixelData)
        )
    }

    private func pixelDifferenceRatio(_ lhs: RasterImage, _ rhs: RasterImage) -> Double? {
        let lhsBytes = lhs.bytes
        let rhsBytes = rhs.bytes
        guard lhs.width == rhs.width,
              lhs.height == rhs.height,
              lhsBytes.count == rhsBytes.count else {
            return nil
        }

        let bytesPerPixel = 4
        let pixelCount = lhs.width * lhs.height
        var changedPixels = 0
        let threshold = 8

        var index = 0
        while index < lhsBytes.count {
            let lhsBlue = Int(lhsBytes[index])
            let lhsGreen = Int(lhsBytes[index + 1])
            let lhsRed = Int(lhsBytes[index + 2])
            let lhsAlpha = Int(lhsBytes[index + 3])

            let rhsBlue = Int(rhsBytes[index])
            let rhsGreen = Int(rhsBytes[index + 1])
            let rhsRed = Int(rhsBytes[index + 2])
            let rhsAlpha = Int(rhsBytes[index + 3])

            let changed = abs(lhsRed - rhsRed) > threshold
                || abs(lhsGreen - rhsGreen) > threshold
                || abs(lhsBlue - rhsBlue) > threshold
                || abs(lhsAlpha - rhsAlpha) > threshold

            if changed {
                changedPixels += 1
            }
            index += bytesPerPixel
        }

        return Double(changedPixels) / Double(pixelCount)
    }
}

private struct DemoBrowserBaselineCase {
    let sampleID: String
    let baselineName: String
    let sourceSVGPath: String
    let expectedSize: CGSize?

    init(sampleID: String, baselineName: String, sourceSVGPath: String) {
        self.sampleID = sampleID
        self.baselineName = baselineName
        self.sourceSVGPath = sourceSVGPath
        self.expectedSize = nil
    }

    init(
        sampleID: String,
        baselineName: String,
        sourceSVGPath: String,
        expectedSize: CGSize?
    ) {
        self.sampleID = sampleID
        self.baselineName = baselineName
        self.sourceSVGPath = sourceSVGPath
        self.expectedSize = expectedSize
    }
}

    private func loadBrowserBaselineCases() throws -> [DemoBrowserBaselineCase] {
        guard let manifestURL = findBrowserOracleManifestURL() else {
            throw NSError(
                domain: "BrowserOracleManifest",
                code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "브라우저 오라클 매니페스트를 찾을 수 없습니다. " +
                    "예상 파일: Scripts/browser-oracle/browser-oracle-manifest.json"
            ]
        )
        }
        let rawData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(BrowserOracleManifest.self, from: rawData)
        let manifestDirectory = manifestURL.deletingLastPathComponent().path
        return manifest.cases.map { entry in
            let svgPath = (manifestDirectory as NSString).appendingPathComponent(entry.svg)
            let svgURL = URL(fileURLWithPath: svgPath).standardized
            let sampleID = entry.sampleID ?? svgURL.deletingPathExtension().lastPathComponent
            let expectedSize = makeExpectedSize(from: entry.size)
            return DemoBrowserBaselineCase(
                sampleID: sampleID,
                baselineName: entry.name,
                sourceSVGPath: svgURL.path,
                expectedSize: expectedSize
            )
        }
    }

    private func makeExpectedSize(from size: BrowserOracleManifestSize?) -> CGSize? {
        guard let size else {
            return nil
        }
        guard let widthValue = size.width, let heightValue = size.height else {
            return nil
        }
        if widthValue <= 0 || heightValue <= 0 {
            return nil
        }
        return CGSize(width: widthValue, height: heightValue)
    }

private func findBrowserOracleManifestURL() -> URL? {
    let manifestFileName = "browser-oracle-manifest.json"
    let fileManager = FileManager.default
    let processInfo = ProcessInfo.processInfo

    var candidateRoots = [URL]()
    let sourceFileURL = URL(fileURLWithPath: String(describing: #filePath))
    var scanningRoot = sourceFileURL.deletingLastPathComponent()
    for _ in 0..<12 {
        candidateRoots.append(scanningRoot)
        scanningRoot = scanningRoot.deletingLastPathComponent()
    }

    if let projectDir = processInfo.environment["PROJECT_DIR"] {
        candidateRoots.append(URL(fileURLWithPath: projectDir))
    }
    if let sourceRoot = processInfo.environment["SRCROOT"] {
        candidateRoots.append(URL(fileURLWithPath: sourceRoot))
    }
    if let currentWorkingDirectory = processInfo.environment["PWD"] {
        candidateRoots.append(URL(fileURLWithPath: currentWorkingDirectory))
    }
    candidateRoots.append(URL(fileURLWithPath: fileManager.currentDirectoryPath))

    var seenRoots = Set<String>()
    for root in candidateRoots {
        let rootPath = root.standardized.path
        if seenRoots.contains(rootPath) {
            continue
        }
        seenRoots.insert(rootPath)

        var currentRoot = root
        for _ in 0..<12 {
            let manifestURL = currentRoot
                .appendingPathComponent("Scripts", isDirectory: true)
                .appendingPathComponent("browser-oracle", isDirectory: true)
                .appendingPathComponent(manifestFileName)
            if fileManager.fileExists(atPath: manifestURL.path) {
                return manifestURL.standardized
            }

            let parent = currentRoot.deletingLastPathComponent()
            if parent == currentRoot {
                break
            }
            currentRoot = parent
        }
    }

    return nil
}

private struct BrowserOracleManifest: Decodable {
    let cases: [BrowserOracleManifestEntry]
}

private struct BrowserOracleManifestEntry: Decodable {
    let name: String
    let svg: String
    let sampleID: String?
    let size: BrowserOracleManifestSize?
}

private struct BrowserOracleManifestSize: Decodable {
    let width: Int?
    let height: Int?
}

private enum SnapshotMode {
    case compare
    case record

    static func current(sourceFilePath: StaticString) -> SnapshotMode {
        let value = ProcessInfo.processInfo.environment["SVG_DEMO_RECORD_BASELINES"] ?? ""
        let lowercasedValue = value.lowercased()
        let explicitMode = value == "1" || lowercasedValue == "true" || lowercasedValue == "yes"
        if explicitMode {
            return .record
        }

        let sourcePath = String(describing: sourceFilePath)
        let sourceFileURL = URL(fileURLWithPath: sourcePath)
        let sourceDirectory = sourceFileURL.deletingLastPathComponent()
        let markerURL = sourceDirectory.appendingPathComponent("Baselines", isDirectory: true).appendingPathComponent(".record")
        if FileManager.default.fileExists(atPath: markerURL.path) {
            return .record
        }
        return .compare
    }
}

private struct SnapshotComparator {
    struct PixelComparisonResult {
        let mismatchRatio: Double
        let reason: String?
        let diffImageData: Data?
    }

    let mode: SnapshotMode
    let tolerance: Double
    let comparisonTolerance: Double
    let referenceDirectory: URL?
    let useBrowserReference: Bool
    private let fileManager = FileManager.default

    @MainActor
    func assertMatchesBaseline(
        rasterImage: RasterImage,
        baselineName: String,
        sourceFilePath: StaticString,
        compareTargetSize: CGSize? = nil
    ) {
        guard let actualImageData = makePNGData(fromRGBA8Pixels: rasterImage.bytes, width: rasterImage.width, height: rasterImage.height) else {
            XCTFail("Could not encode canvas raster image data.")
            return
        }
        assertMatchesBaseline(
            actualImageData: actualImageData,
            baselineName: baselineName,
            sourceFilePath: sourceFilePath,
            compareTargetSize: compareTargetSize
        )
    }

    @MainActor
    func assertMatchesBaseline(
        screenshot: XCUIScreenshot,
        baselineName: String,
        sourceFilePath: StaticString,
        compareTargetSize: CGSize? = nil
    ) {
        assertMatchesBaseline(
            actualImageData: screenshot.pngRepresentation,
            baselineName: baselineName,
            sourceFilePath: sourceFilePath,
            compareTargetSize: compareTargetSize
        )
    }

    @MainActor
    private func assertMatchesBaseline(
        actualImageData: Data,
        baselineName: String,
        sourceFilePath: StaticString,
        compareTargetSize: CGSize? = nil
    ) {
        let baselineURL = baselineFileURL(name: baselineName, sourceFilePath: sourceFilePath)
        let baselineDirectory = baselineURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(
                at: baselineDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            XCTFail("Failed to create baseline directory: \(baselineDirectory.path). Error: \(error)")
            return
        }

        switch mode {
        case .record:
            do {
                try actualImageData.write(to: baselineURL, options: .atomic)
            } catch {
                XCTFail("Failed to record baseline: \(baselineURL.path). Error: \(error)")
            }
            return
        case .compare:
            break
        }

        if !fileManager.fileExists(atPath: baselineURL.path) {
            let missingMessage = "Missing baseline image: \(baselineURL.path). " +
                "Run with SVG_BROWSER_REFERENCE_DIR or .record mode to generate baseline."
            if useBrowserReference {
                XCTFail(missingMessage)
            } else {
                XCTFail(missingMessage)
            }
            return
        }

        guard let expectedImageData = try? Data(contentsOf: baselineURL) else {
            XCTFail("Failed to load baseline image: \(baselineURL.path)")
            return
        }
        let comparison = compare(
            expectedImageData: expectedImageData,
            actualImageData: actualImageData,
            compareTargetSize: compareTargetSize
        )
        if let reason = comparison.reason {
            XCTFail("Baseline comparison failed for \(baselineName): \(reason)")
            return
        }
        if comparison.mismatchRatio > tolerance {
            let artifactsDirectoryURL = makeArtifactsDirectory(baselineName: baselineName)
            let expectedURL = artifactsDirectoryURL.appendingPathComponent("\(baselineName).expected.png")
            let actualURL = artifactsDirectoryURL.appendingPathComponent("\(baselineName).actual.png")
            let diffURL = artifactsDirectoryURL.appendingPathComponent("\(baselineName).diff.png")
            try? expectedImageData.write(to: expectedURL, options: .atomic)
            try? actualImageData.write(to: actualURL, options: .atomic)
            if let diffImageData = comparison.diffImageData {
                try? diffImageData.write(to: diffURL, options: .atomic)
            }

            let mismatchString = String(format: "%.4f%%", comparison.mismatchRatio * 100.0)
            XCTFail(
                "Baseline mismatch (\(mismatchString)) for \(baselineName). " +
                "Artifacts: \(artifactsDirectoryURL.path)"
            )
        }
    }

    private func baselineFileURL(name: String, sourceFilePath: StaticString) -> URL {
        if let referenceDirectory {
            return referenceDirectory.appendingPathComponent("\(name).png")
        }
        let sourcePath = String(describing: sourceFilePath)
        let sourceFileURL = URL(fileURLWithPath: sourcePath)
        let sourceDirectoryURL = sourceFileURL.deletingLastPathComponent()
        let deviceName = (ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "UnknownDevice").fileSystemSafeString()
        let runtimeVersion = (ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_VERSION"] ?? "UnknownRuntime").fileSystemSafeString()
        return sourceDirectoryURL
            .appendingPathComponent("Baselines", isDirectory: true)
            .appendingPathComponent(deviceName, isDirectory: true)
            .appendingPathComponent(runtimeVersion, isDirectory: true)
            .appendingPathComponent("\(name).png")
    }

    private func makeArtifactsDirectory(baselineName: String) -> URL {
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let timestamp = makeTimestampString(Date())
        let artifactsDirectoryURL = tempDirectoryURL
            .appendingPathComponent("SVGSwiftUIDemoSnapshotArtifacts", isDirectory: true)
            .appendingPathComponent(timestamp, isDirectory: true)
            .appendingPathComponent(baselineName, isDirectory: true)
        try? fileManager.createDirectory(at: artifactsDirectoryURL, withIntermediateDirectories: true)
        return artifactsDirectoryURL
    }

    private func makeTimestampString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        let rawTimestamp = formatter.string(from: date)
        return rawTimestamp.replacingOccurrences(of: ":", with: "-")
    }

    private func compare(
        expectedImageData: Data,
        actualImageData: Data,
        compareTargetSize: CGSize?
    ) -> PixelComparisonResult {
        guard let expectedImage = makeCGImage(from: expectedImageData) else {
            return PixelComparisonResult(
                mismatchRatio: 1.0,
                reason: "Unable to decode expected PNG.",
                diffImageData: nil
            )
        }
        guard let actualImage = makeCGImage(from: actualImageData) else {
            return PixelComparisonResult(
                mismatchRatio: 1.0,
                reason: "Unable to decode actual PNG.",
                diffImageData: nil
            )
        }

        let resolvedTargetSize = resolvedCompareTargetSize(
            requested: compareTargetSize,
            expectedImage: expectedImage,
            actualImage: actualImage
        )
        let targetWidth = Int(resolvedTargetSize.width)
        let targetHeight = Int(resolvedTargetSize.height)
        if targetWidth <= 0 || targetHeight <= 0 {
            return PixelComparisonResult(
                mismatchRatio: 1.0,
                reason: "Invalid compare target size.",
                diffImageData: nil
            )
        }

        let expectedRaster = rasterizeCGImage(
            expectedImage,
            to: CGSize(width: targetWidth, height: targetHeight),
            preserveAspect: true
        )
        let actualRaster = rasterizeCGImage(
            actualImage,
            to: CGSize(width: targetWidth, height: targetHeight),
            preserveAspect: true
        )
        guard let normalizedExpected = expectedRaster else {
            return PixelComparisonResult(mismatchRatio: 1.0, reason: "Unable to normalize expected image pixels.", diffImageData: nil)
        }
        guard let normalizedActual = actualRaster else {
            return PixelComparisonResult(mismatchRatio: 1.0, reason: "Unable to normalize actual image pixels.", diffImageData: nil)
        }

        let expectedBytes = normalizedExpected.bytes
        let actualBytes = normalizedActual.bytes
        let pixelCount = targetWidth * targetHeight
        if pixelCount == 0 {
            return PixelComparisonResult(mismatchRatio: 0.0, reason: nil, diffImageData: nil)
        }

        var mismatchCount = 0
        let bytesPerPixel = 4
        let channelTolerance = clampTolerance(comparisonTolerance)
        var diffBytes = [UInt8](repeating: 0, count: expectedBytes.count)

        var offset = 0
        for _ in 0..<pixelCount {
            let expectedRed = expectedBytes[offset]
            let expectedGreen = expectedBytes[offset + 1]
            let expectedBlue = expectedBytes[offset + 2]
            let expectedAlpha = expectedBytes[offset + 3]

            let actualRed = actualBytes[offset]
            let actualGreen = actualBytes[offset + 1]
            let actualBlue = actualBytes[offset + 2]
            let actualAlpha = actualBytes[offset + 3]

            let differs = absDifference(expectedRed, actualRed) > channelTolerance
                || absDifference(expectedGreen, actualGreen) > channelTolerance
                || absDifference(expectedBlue, actualBlue) > channelTolerance
                || absDifference(expectedAlpha, actualAlpha) > channelTolerance

            if differs {
                mismatchCount += 1
                diffBytes[offset] = 255
                diffBytes[offset + 1] = 0
                diffBytes[offset + 2] = 0
                diffBytes[offset + 3] = 255
            } else {
                let average = Int(expectedRed) + Int(expectedGreen) + Int(expectedBlue)
                let grayValue = UInt8(average / 3)
                diffBytes[offset] = grayValue
                diffBytes[offset + 1] = grayValue
                diffBytes[offset + 2] = grayValue
                diffBytes[offset + 3] = 90
            }

            offset += bytesPerPixel
        }

        let mismatchRatio = Double(mismatchCount) / Double(pixelCount)
        let diffImageData = mismatchCount > 0
            ? makePNGData(fromRGBA8Pixels: diffBytes, width: targetWidth, height: targetHeight)
            : nil

        return PixelComparisonResult(
            mismatchRatio: mismatchRatio,
            reason: nil,
            diffImageData: diffImageData
        )
    }

    private func resolvedCompareTargetSize(
        requested compareTargetSize: CGSize?,
        expectedImage: CGImage,
        actualImage: CGImage
    ) -> CGSize {
        guard let requestedTarget = compareTargetSize else {
            return CGSize(width: CGFloat(expectedImage.width), height: CGFloat(expectedImage.height))
        }
        return requestedTarget
    }

    private func clampTolerance(_ value: Double) -> UInt8 {
        if !value.isFinite {
            return 2
        }
        let rounded = Int(value.rounded())
        if rounded < 0 {
            return 0
        }
        if rounded > 255 {
            return 255
        }
        return UInt8(rounded)
    }

    private func makeCGImage(from imageData: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func rasterizeCGImage(_ image: CGImage, to size: CGSize, preserveAspect: Bool) -> RasterImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        if width <= 0 || height <= 0 {
            return nil
        }

        let sourceWidth = image.width
        let sourceHeight = image.height
        if sourceWidth <= 0 || sourceHeight <= 0 {
            return nil
        }

        let normalizedSourceImage: CGImage
        if !preserveAspect {
            normalizedSourceImage = image
        } else {
            let targetAspect = Double(width) / Double(height)
            let sourceAspect = Double(sourceWidth) / Double(sourceHeight)
            let aspectDiff = abs(targetAspect - sourceAspect)
            if aspectDiff < 0.0001 {
                normalizedSourceImage = image
            } else {
                let shouldCropWidth = sourceAspect > targetAspect
                normalizedSourceImage = shouldCropWidth
                    ? cropToTargetWidth(image: image, targetAspect: targetAspect) ?? image
                    : cropToTargetHeight(image: image, targetAspect: targetAspect) ?? image
            }
        }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let imageByteCount = width * height * bytesPerPixel
        if imageByteCount <= 0 {
            return nil
        }

        var pixelData = Data(count: imageByteCount)
        let drawWidth = CGFloat(width)
        let drawHeight = CGFloat(height)
        let conversionSucceeded = pixelData.withUnsafeMutableBytes { rawBytes in
            guard let bufferPointer = rawBytes.bindMemory(to: UInt8.self).baseAddress else {
                return false
            }
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
                CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            )

            guard let context = CGContext(
                data: bufferPointer,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                return false
            }

            let sourceToTargetScaleX = Double(width) / Double(sourceWidth)
            let sourceToTargetScaleY = Double(height) / Double(sourceHeight)

            let isIdentityScaleX = abs(sourceToTargetScaleX - 1.0) <= 0.000_001
            let isIdentityScaleY = abs(sourceToTargetScaleY - 1.0) <= 0.000_001
            let useNearestResize = isIdentityScaleX && isIdentityScaleY

            context.interpolationQuality = useNearestResize ? .none : .high
            context.setShouldAntialias(!useNearestResize)
            context.draw(
                normalizedSourceImage,
                in: CGRect(x: 0.0, y: 0.0, width: drawWidth, height: drawHeight)
            )
            return true
        }
        if !conversionSucceeded {
            return nil
        }
        return RasterImage(
            width: width,
            height: height,
            bytes: Array(pixelData)
        )
    }

    private func isIntegerScaleFactor(_ value: Double) -> Bool {
        if !value.isFinite || value <= 0.0 {
            return false
        }
        if abs(value - 1.0) <= 0.000_001 {
            return true
        }
        if value < 1.0 {
            return false
        }
        let rounded = value.rounded()
        return abs(rounded - value) <= 0.001
    }

    private func cropToTargetWidth(image: CGImage, targetAspect: Double) -> CGImage? {
        let sourceWidth = image.width
        let sourceHeight = image.height
        if sourceWidth <= 0 || sourceHeight <= 0 || !targetAspect.isFinite || targetAspect <= 0.0 {
            return nil
        }

        let desiredWidth = Int(Double(sourceHeight) * targetAspect)
        let clampedWidth = max(1, min(sourceWidth, desiredWidth))
        let x = max(0, (sourceWidth - clampedWidth) / 2)
        let cropRect = CGRect(
            x: x,
            y: 0,
            width: clampedWidth,
            height: sourceHeight
        )
        return image.cropping(to: cropRect)
    }

    private func cropToTargetHeight(image: CGImage, targetAspect: Double) -> CGImage? {
        let sourceWidth = image.width
        let sourceHeight = image.height
        if sourceWidth <= 0 || sourceHeight <= 0 || !targetAspect.isFinite || targetAspect <= 0.0 {
            return nil
        }

        let desiredHeight = Int(Double(sourceWidth) / targetAspect)
        let clampedHeight = max(1, min(sourceHeight, desiredHeight))
        let y = max(0, (sourceHeight - clampedHeight) / 2)
        let cropRect = CGRect(
            x: 0,
            y: y,
            width: sourceWidth,
            height: clampedHeight
        )
        return image.cropping(to: cropRect)
    }

    private func makePNGData(fromRGBA8Pixels pixels: [UInt8], width: Int, height: Int) -> Data? {
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = width * bytesPerPixel
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let pixelData = Data(pixels) as CFData
        guard let provider = CGDataProvider(data: pixelData) else {
            return nil
        }
        guard let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bytesPerPixel * bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            return nil
        }

        guard let destinationData = CFDataCreateMutable(nil, 0) else {
            return nil
        }
        guard let destination = CGImageDestinationCreateWithData(
            destinationData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return destinationData as Data
    }

    private func absDifference(_ lhs: UInt8, _ rhs: UInt8) -> UInt8 {
        let left = Int(lhs)
        let right = Int(rhs)
        return UInt8(abs(left - right))
    }
}

private extension CGRect {
    func isValid() -> Bool {
        return !isNull
            && !width.isNaN
            && !height.isNaN
            && !width.isInfinite
            && !height.isInfinite
            && width >= 0
            && height >= 0
    }
}

private extension String {
    func fileSystemSafeString() -> String {
        let value = self
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let characters = value.unicodeScalars.compactMap { scalar -> Character? in
            if allowedCharacters.contains(scalar) {
                return Character(scalar)
            }
            return "_"
        }
        let safeString = String(characters)
        if safeString.isEmpty {
            return "unknown"
        }
        return safeString
    }
}

private struct RasterImage {
    let width: Int
    let height: Int
    let bytes: [UInt8]
}
