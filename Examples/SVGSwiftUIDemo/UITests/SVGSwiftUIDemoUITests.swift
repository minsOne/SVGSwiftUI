import XCTest
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

final class SVGSwiftUIDemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsCanvasAndControls() {
        let app = launchApp()
        XCTAssertTrue(app.otherElements["demo.canvas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["demo.controls"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["demo.cacheStats"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["demo.cache.requests"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["demo.cache.hits"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["demo.cache.misses"].waitForExistence(timeout: 5))
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
    func testCanvasMatchesBaselines() {
        let app = launchApp()
        let referenceDirectory = browserReferenceDirectory()
        let referenceImageTolerance = browserImageTolerance()

        assertCanvasBaseline(
            app,
            name: "badge_default",
            referenceDirectory: referenceDirectory,
            comparisonTolerance: referenceImageTolerance
        )

        selectSample(app, index: 1)
        setSwitch(app.switches["demo.fillToggle"], isOn: true)
        setSwitch(app.switches["demo.strokeToggle"], isOn: true)
        setSlider(app.sliders["demo.scaleSlider"], normalizedValue: 0.25)
        setSlider(app.sliders["demo.offsetXSlider"], normalizedValue: 0.5)
        setSlider(app.sliders["demo.offsetYSlider"], normalizedValue: 0.5)
        assertCanvasBaseline(
            app,
            name: "panel_stroke",
            referenceDirectory: referenceDirectory,
            comparisonTolerance: referenceImageTolerance
        )

        selectSample(app, index: 2)
        setSwitch(app.switches["demo.fillToggle"], isOn: true)
        setSwitch(app.switches["demo.strokeToggle"], isOn: false)
        setSlider(app.sliders["demo.scaleSlider"], normalizedValue: 0.25)
        setSlider(app.sliders["demo.offsetXSlider"], normalizedValue: 0.75)
        setSlider(app.sliders["demo.offsetYSlider"], normalizedValue: 0.25)
        assertCanvasBaseline(
            app,
            name: "route_offset",
            referenceDirectory: referenceDirectory,
            comparisonTolerance: referenceImageTolerance
        )
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    private func selectSample(_ app: XCUIApplication, index: Int) {
        let sampleList = app.segmentedControls["demo.sampleList"]
        XCTAssertTrue(sampleList.waitForExistence(timeout: 5))
        XCTAssertTrue(sampleList.buttons.count > index)
        sampleList.buttons.element(boundBy: index).tap()
        waitForRenderSettled()
    }

    @MainActor
    private func setSwitch(_ toggle: XCUIElement, isOn: Bool) {
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        guard let currentValue = switchValue(toggle) else {
            toggle.tap()
            return
        }
        if currentValue != isOn {
            toggle.tap()
        }
    }

    @MainActor
    private func setSlider(_ slider: XCUIElement, normalizedValue: Double) {
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        let clampedValue = min(max(normalizedValue, 0.0), 1.0)
        slider.adjust(toNormalizedSliderPosition: clampedValue)
        waitForRenderSettled()
    }

    @MainActor
    private func assertCanvasBaseline(
        _ app: XCUIApplication,
        name: String,
        referenceDirectory: URL?,
        comparisonTolerance: Double = 0.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let canvas = app.otherElements["demo.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5), file: file, line: line)
        waitForRenderSettled()
        let screenshot = canvas.screenshot()
        let mode = SnapshotMode.current(sourceFilePath: file)
        let comparator = SnapshotComparator(
            mode: mode,
            tolerance: 0.005,
            comparisonTolerance: comparisonTolerance,
            referenceDirectory: referenceDirectory
        )
        comparator.assertMatchesBaseline(
            screenshot: screenshot,
            baselineName: name,
            file: file,
            line: line
        )
    }

    private func browserReferenceDirectory() -> URL? {
        guard let value = ProcessInfo.processInfo.environment["SVG_BROWSER_REFERENCE_DIR"], !value.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: value)
    }

    private func browserImageTolerance() -> Double {
        guard let value = ProcessInfo.processInfo.environment["SVG_BROWSER_REFERENCE_TOLERANCE"] else {
            return 2.0
        }
        guard let parsed = Double(value) else {
            return 2.0
        }
        return max(0.0, parsed)
    }

    @MainActor
    private func switchValue(_ toggle: XCUIElement) -> Bool? {
        if let boolValue = toggle.value as? Bool {
            return boolValue
        }
        if let numberValue = toggle.value as? NSNumber {
            return numberValue.boolValue
        }
        guard let stringValue = toggle.value as? String else {
            return nil
        }
        let normalizedValue = stringValue.lowercased()
        if normalizedValue == "1" || normalizedValue == "on" || normalizedValue == "true" {
            return true
        }
        if normalizedValue == "0" || normalizedValue == "off" || normalizedValue == "false" {
            return false
        }
        return nil
    }

    private func waitForRenderSettled() {
        let delayInMicroseconds: useconds_t = 350_000
        usleep(delayInMicroseconds)
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

private enum SnapshotMode {
    case compare
    case record

    static func current(sourceFilePath: StaticString) -> SnapshotMode {
        let value = ProcessInfo.processInfo.environment["SVG_DEMO_RECORD_BASELINES"] ?? ""
        let normalizedValue = value.lowercased()
        if value == "1" || normalizedValue == "true" || normalizedValue == "yes" {
            return .record
        }
        let sourcePath = String(describing: sourceFilePath)
        let sourceDirectory = URL(fileURLWithPath: sourcePath).deletingLastPathComponent()
        let markerFileURL = sourceDirectory
            .appendingPathComponent("Baselines", isDirectory: true)
            .appendingPathComponent(".record")
        if FileManager.default.fileExists(atPath: markerFileURL.path) {
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

    private let fileManager = FileManager.default

    @MainActor
    func assertMatchesBaseline(
        screenshot: XCUIScreenshot,
        baselineName: String,
        file: StaticString,
        line: UInt
    ) {
        let baselineURL = baselineFileURL(
            name: baselineName,
            sourceFilePath: file
        )
        let baselineDirectoryURL = baselineURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(
                at: baselineDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            XCTFail("Failed to create baseline directory: \(baselineDirectoryURL.path). Error: \(error)", file: file, line: line)
            return
        }

        let actualImageData = screenshot.pngRepresentation
        switch mode {
        case .record:
            do {
                try actualImageData.write(to: baselineURL, options: .atomic)
            } catch {
                XCTFail("Failed to record baseline: \(baselineURL.path). Error: \(error)", file: file, line: line)
            }
            return
        case .compare:
            break
        }

        guard fileManager.fileExists(atPath: baselineURL.path) else {
            let artifactsDirectoryURL = makeArtifactsDirectory(baselineName: baselineName)
            let actualURL = artifactsDirectoryURL.appendingPathComponent("\(baselineName).actual.png")
            try? actualImageData.write(to: actualURL, options: .atomic)
            XCTFail(
                "Missing baseline image: \(baselineURL.path). Actual image saved at: \(actualURL.path). " +
                "Create UITests/Baselines/.record (or set SVG_DEMO_RECORD_BASELINES=1) to generate baselines.",
                file: file,
                line: line
            )
            return
        }

        let expectedImageData: Data
        do {
            expectedImageData = try Data(contentsOf: baselineURL)
        } catch {
            XCTFail("Failed to load baseline image: \(baselineURL.path). Error: \(error)", file: file, line: line)
            return
        }

        let comparisonResult = compare(
            expectedImageData: expectedImageData,
            actualImageData: actualImageData
        )

        if let reason = comparisonResult.reason {
            XCTFail("Baseline comparison failed for \(baselineName): \(reason)", file: file, line: line)
            return
        }

        if comparisonResult.mismatchRatio > tolerance {
            let artifactsDirectoryURL = makeArtifactsDirectory(baselineName: baselineName)
            let expectedURL = artifactsDirectoryURL.appendingPathComponent("\(baselineName).expected.png")
            let actualURL = artifactsDirectoryURL.appendingPathComponent("\(baselineName).actual.png")
            let diffURL = artifactsDirectoryURL.appendingPathComponent("\(baselineName).diff.png")

            try? expectedImageData.write(to: expectedURL, options: .atomic)
            try? actualImageData.write(to: actualURL, options: .atomic)
            if let diffImageData = comparisonResult.diffImageData {
                try? diffImageData.write(to: diffURL, options: .atomic)
            }

            let ratioString = String(format: "%.4f%%", comparisonResult.mismatchRatio * 100.0)
            XCTFail(
                "Baseline mismatch (\(ratioString)) for \(baselineName). " +
                "Artifacts: \(artifactsDirectoryURL.path)",
                file: file,
                line: line
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
        let deviceName = sanitizePathComponent(
            ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "UnknownDevice"
        )
        let runtimeVersion = sanitizePathComponent(
            ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_VERSION"] ?? "UnknownRuntime"
        )

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
        try? fileManager.createDirectory(
            at: artifactsDirectoryURL,
            withIntermediateDirectories: true
        )
        return artifactsDirectoryURL
    }

    private func makeTimestampString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        let rawTimestamp = formatter.string(from: date)
        return rawTimestamp.replacingOccurrences(of: ":", with: "-")
    }

    private func sanitizePathComponent(_ value: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-_."))
        let mappedScalars = value.unicodeScalars.map { scalar -> Character in
            if allowedCharacters.contains(scalar) {
                return Character(scalar)
            }
            return "_"
        }
        return String(mappedScalars)
    }

    private func compare(expectedImageData: Data, actualImageData: Data) -> PixelComparisonResult {
        guard let expectedImage = makeCGImage(from: expectedImageData) else {
            return PixelComparisonResult(mismatchRatio: 1.0, reason: "Unable to decode expected PNG.", diffImageData: nil)
        }
        guard let actualImage = makeCGImage(from: actualImageData) else {
            return PixelComparisonResult(mismatchRatio: 1.0, reason: "Unable to decode actual PNG.", diffImageData: nil)
        }

        let expectedWidth = expectedImage.width
        let expectedHeight = expectedImage.height
        let actualWidth = actualImage.width
        let actualHeight = actualImage.height

        guard expectedWidth == actualWidth, expectedHeight == actualHeight else {
            let reason = "Image size mismatch. expected=\(expectedWidth)x\(expectedHeight), actual=\(actualWidth)x\(actualHeight)"
            return PixelComparisonResult(mismatchRatio: 1.0, reason: reason, diffImageData: nil)
        }

        guard let expectedPixels = rgba8Pixels(from: expectedImage) else {
            return PixelComparisonResult(mismatchRatio: 1.0, reason: "Unable to normalize expected image pixels.", diffImageData: nil)
        }
        guard let actualPixels = rgba8Pixels(from: actualImage) else {
            return PixelComparisonResult(mismatchRatio: 1.0, reason: "Unable to normalize actual image pixels.", diffImageData: nil)
        }

        let pixelCount = expectedWidth * expectedHeight
        if pixelCount == 0 {
            return PixelComparisonResult(mismatchRatio: 0.0, reason: nil, diffImageData: nil)
        }

        var mismatchPixelCount = 0
        var diffPixels = [UInt8](repeating: 0, count: pixelCount * 4)
        var offset = 0

        let channelTolerance = UInt8(min(max(Int(comparisonTolerance.rounded()), 0), 255))
        for _ in 0..<pixelCount {
            let expectedRed = expectedPixels[offset]
            let expectedGreen = expectedPixels[offset + 1]
            let expectedBlue = expectedPixels[offset + 2]
            let expectedAlpha = expectedPixels[offset + 3]

            let actualRed = actualPixels[offset]
            let actualGreen = actualPixels[offset + 1]
            let actualBlue = actualPixels[offset + 2]
            let actualAlpha = actualPixels[offset + 3]

            let differs = absDifference(expectedRed, actualRed) > channelTolerance
                || absDifference(expectedGreen, actualGreen) > channelTolerance
                || absDifference(expectedBlue, actualBlue) > channelTolerance
                || absDifference(expectedAlpha, actualAlpha) > channelTolerance

            if differs {
                mismatchPixelCount += 1
                diffPixels[offset] = 255
                diffPixels[offset + 1] = 0
                diffPixels[offset + 2] = 0
                diffPixels[offset + 3] = 255
            } else {
                let grayValueInt = (
                    Int(expectedRed) +
                    Int(expectedGreen) +
                    Int(expectedBlue)
                ) / 3
                let grayValue = UInt8(grayValueInt)
                diffPixels[offset] = grayValue
                diffPixels[offset + 1] = grayValue
                diffPixels[offset + 2] = grayValue
                diffPixels[offset + 3] = 90
            }

            offset += 4
        }

        let mismatchRatio = Double(mismatchPixelCount) / Double(pixelCount)
        let diffImageData: Data?
        if mismatchPixelCount > 0 {
            diffImageData = makePNGData(fromRGBA8Pixels: diffPixels, width: expectedWidth, height: expectedHeight)
        } else {
            diffImageData = nil
        }
        return PixelComparisonResult(
            mismatchRatio: mismatchRatio,
            reason: nil,
            diffImageData: diffImageData
        )
    }

    private func makeCGImage(from imageData: Data) -> CGImage? {
        let data = imageData as CFData
        guard let imageSource = CGImageSourceCreateWithData(data, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }

    private func absDifference(_ lhs: UInt8, _ rhs: UInt8) -> UInt8 {
        let left = Int(lhs)
        let right = Int(rhs)
        return UInt8(abs(left - right))
    }

    private func rgba8Pixels(from image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(image, in: rect)
        return pixels
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
}
