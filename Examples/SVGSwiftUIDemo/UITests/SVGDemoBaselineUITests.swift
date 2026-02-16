import Foundation
import UIKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest

extension SVGSwiftUIDemoUITests {
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
}
