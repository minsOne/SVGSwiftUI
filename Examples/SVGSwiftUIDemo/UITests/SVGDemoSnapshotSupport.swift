import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest

enum SnapshotMode {
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
        let markerURL = sourceDirectory
            .appendingPathComponent("Baselines", isDirectory: true)
            .appendingPathComponent(".record")
        if FileManager.default.fileExists(atPath: markerURL.path) {
            return .record
        }
        return .compare
    }
}

struct SnapshotComparator {
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
        guard let actualImageData = makePNGData(
            fromRGBA8Pixels: rasterImage.bytes,
            width: rasterImage.width,
            height: rasterImage.height
        ) else {
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
    func assertMatchesBaseline(
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
            let artifactSummary = "\(artifactsDirectoryURL.path)"
            XCTContext.runActivity(named: "Baseline mismatch artifacts: \(baselineName)") { activity in
                let attachment = XCTAttachment(string: artifactSummary)
                attachment.name = "Snapshot artifacts directory"
                attachment.lifetime = .keepAlways
                activity.add(attachment)
                if FileManager.default.fileExists(atPath: expectedURL.path) {
                    if let expectedData = try? Data(contentsOf: expectedURL) {
                        let expectedAttachment = XCTAttachment(data: expectedData, uniformTypeIdentifier: UTType.png.identifier)
                        expectedAttachment.name = "\(baselineName).expected.png"
                        expectedAttachment.lifetime = .keepAlways
                        activity.add(expectedAttachment)
                    }
                }
                if FileManager.default.fileExists(atPath: actualURL.path) {
                    if let actualData = try? Data(contentsOf: actualURL) {
                        let actualAttachment = XCTAttachment(data: actualData, uniformTypeIdentifier: UTType.png.identifier)
                        actualAttachment.name = "\(baselineName).actual.png"
                        actualAttachment.lifetime = .keepAlways
                        activity.add(actualAttachment)
                    }
                }
                if FileManager.default.fileExists(atPath: diffURL.path) {
                    if let diffData = try? Data(contentsOf: diffURL) {
                        let diffAttachment = XCTAttachment(data: diffData, uniformTypeIdentifier: UTType.png.identifier)
                        diffAttachment.name = "\(baselineName).diff.png"
                        diffAttachment.lifetime = .keepAlways
                        activity.add(diffAttachment)
                    }
                }
            }
            XCTFail(
                "Baseline mismatch (\(mismatchString)) for \(baselineName). " +
                    "Artifacts: \(artifactSummary)"
            )
        }
    }

    func baselineFileURL(name: String, sourceFilePath: StaticString) -> URL {
        if let referenceDirectory {
            return referenceDirectory.appendingPathComponent("\(name).png")
        }
        let sourcePath = String(describing: sourceFilePath)
        let sourceFileURL = URL(fileURLWithPath: sourcePath)
        let sourceDirectoryURL = sourceFileURL.deletingLastPathComponent()
        let deviceName = (ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "UnknownDevice")
            .fileSystemSafeString()
        let runtimeVersion = (ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_VERSION"] ?? "UnknownRuntime")
            .fileSystemSafeString()
        return sourceDirectoryURL
            .appendingPathComponent("Baselines", isDirectory: true)
            .appendingPathComponent(deviceName, isDirectory: true)
            .appendingPathComponent(runtimeVersion, isDirectory: true)
            .appendingPathComponent("\(name).png")
    }

    func makeArtifactsDirectory(baselineName: String) -> URL {
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let configuredDirectory = ProcessInfo.processInfo.environment["SVG_BROWSER_COMPARISON_ARTIFACT_DIR"] ?? ""
        let artifactRootURL = configuredDirectory.isEmpty
            ? tempDirectoryURL
                .appendingPathComponent("SVGSwiftUIDemoSnapshotArtifacts", isDirectory: true)
            : URL(fileURLWithPath: configuredDirectory, isDirectory: true)
        let timestamp = makeTimestampString(Date())
        let artifactsDirectoryURL = artifactRootURL
            .appendingPathComponent(timestamp, isDirectory: true)
            .appendingPathComponent(baselineName, isDirectory: true)
        try? fileManager.createDirectory(atPath: artifactsDirectoryURL.path, withIntermediateDirectories: true)
        return artifactsDirectoryURL
    }

    func makeTimestampString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        let rawTimestamp = formatter.string(from: date)
        return rawTimestamp.replacingOccurrences(of: ":", with: "-")
    }

    func compare(
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
            return PixelComparisonResult(
                mismatchRatio: 1.0,
                reason: "Unable to normalize expected image pixels.",
                diffImageData: nil
            )
        }
        guard let normalizedActual = actualRaster else {
            return PixelComparisonResult(
                mismatchRatio: 1.0,
                reason: "Unable to normalize actual image pixels.",
                diffImageData: nil
            )
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

    func resolvedCompareTargetSize(
        requested compareTargetSize: CGSize?,
        expectedImage: CGImage,
        actualImage: CGImage
    ) -> CGSize {
        guard let requestedTarget = compareTargetSize else {
            return CGSize(width: CGFloat(expectedImage.width), height: CGFloat(expectedImage.height))
        }
        guard requestedTarget.width > 0, requestedTarget.height > 0 else {
            return CGSize(width: CGFloat(expectedImage.width), height: CGFloat(expectedImage.height))
        }

        let requestedWidth = requestedTarget.width
        let requestedHeight = requestedTarget.height
        let sourceScaleX = Double(actualImage.width) / Double(requestedWidth)
        let sourceScaleY = Double(actualImage.height) / Double(requestedHeight)
        let isScaleXAligned = isNearIntegerScale(sourceScaleX)
        let isScaleYAligned = isNearIntegerScale(sourceScaleY)
        let isScaleConsistent = sourceScaleX.isFinite && sourceScaleY.isFinite
            && abs(sourceScaleX - sourceScaleY) < 0.05
            && sourceScaleX > 1.0
        if isScaleXAligned && isScaleYAligned && isScaleConsistent {
            return CGSize(width: CGFloat(actualImage.width), height: CGFloat(actualImage.height))
        }
        return requestedTarget
    }

    func isNearIntegerScale(_ value: Double) -> Bool {
        guard value.isFinite else {
            return false
        }
        guard value > 0 else {
            return false
        }
        let rounded = value.rounded()
        return abs(value - rounded) <= 0.05
    }

    func clampTolerance(_ value: Double) -> UInt8 {
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

    func makeCGImage(from imageData: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    func rasterizeCGImage(_ image: CGImage, to size: CGSize, preserveAspect: Bool) -> RasterImage? {
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
        return RasterImage(width: width, height: height, bytes: Array(pixelData))
    }

    func cropToTargetWidth(image: CGImage, targetAspect: Double) -> CGImage? {
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

    func cropToTargetHeight(image: CGImage, targetAspect: Double) -> CGImage? {
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

    func makePNGData(fromRGBA8Pixels pixels: [UInt8], width: Int, height: Int) -> Data? {
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

    func absDifference(_ lhs: UInt8, _ rhs: UInt8) -> UInt8 {
        let left = Int(lhs)
        let right = Int(rhs)
        return UInt8(abs(left - right))
    }
}

extension CGRect {
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

extension String {
    func fileSystemSafeString() -> String {
        let value = self
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "-_."))
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

struct RasterImage {
    let width: Int
    let height: Int
    let bytes: [UInt8]
}
