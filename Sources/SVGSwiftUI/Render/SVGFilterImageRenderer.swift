import CoreGraphics
import CoreImage
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

internal enum SVGFilterImageRenderer {
    private static let sourceGraphicName: String = "SourceGraphic"
    private static let sourceAlphaName: String = "SourceAlpha"

    private static let ciContext: CIContext = CIContext(
        options: [CIContextOption.useSoftwareRenderer: false]
    )

    static func requiresOffscreenProcessing(_ primitives: [SVGFilterPrimitive]) -> Bool {
        for primitive in primitives {
            switch primitive {
            case .blend, .colorMatrix, .composite:
                return true
            case .gaussianBlur, .offset, .unsupported:
                continue
            }
        }
        return false
    }

    static func renderFilteredImage(
        path: Path,
        fillColor: Color?,
        fillStyle: FillStyle,
        strokeColor: Color?,
        strokeWidth: CGFloat,
        lineCap: CGLineCap,
        lineJoin: CGLineJoin,
        miterLimit: CGFloat,
        dash: [CGFloat],
        dashPhase: CGFloat,
        opacity: Double,
        size: CGSize,
        primitives: [SVGFilterPrimitive]
    ) -> CGImage? {
        let normalizedSize: CGSize = normalizeRenderSize(size)
        guard let sourceImage: CIImage = rasterizedImage(
            path: path,
            fillColor: fillColor,
            fillStyle: fillStyle,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            lineCap: lineCap,
            lineJoin: lineJoin,
            miterLimit: miterLimit,
            dash: dash,
            dashPhase: dashPhase,
            opacity: opacity,
            size: normalizedSize
        ) else {
            return nil
        }

        let sourceExtent: CGRect = CGRect(origin: .zero, size: normalizedSize)
        guard let sourceAlphaImage: CIImage = alphaImage(from: sourceImage, extent: sourceExtent) else {
            return nil
        }
        var sourceMap: [String: CIImage] = [
            sourceGraphicName: sourceImage,
            sourceAlphaName: sourceAlphaImage
        ]
        var currentOutput: CIImage = sourceImage

        for primitive in primitives {
            if !SVGFilterGraphExecutor.canExecute(primitive, availableSources: Set(sourceMap.keys)) {
                continue
            }
            if let nextOutput: CIImage = applyPrimitive(
                primitive,
                availableSources: sourceMap,
                fallbackExtent: sourceExtent
            ) {
                currentOutput = nextOutput
                if let resultName: String = SVGFilterGraphExecutor.resolvedResultName(for: primitive) {
                    sourceMap[resultName] = nextOutput
                }
            }
        }

        return ciContext.createCGImage(
            currentOutput,
            from: sourceExtent
        )
    }

    private static func normalizeRenderSize(_ size: CGSize) -> CGSize {
        let width: CGFloat = max(size.width, 1)
        let height: CGFloat = max(size.height, 1)
        return CGSize(width: width, height: height)
    }

    private static func rasterizedImage(
        path: Path,
        fillColor: Color?,
        fillStyle: FillStyle,
        strokeColor: Color?,
        strokeWidth: CGFloat,
        lineCap: CGLineCap,
        lineJoin: CGLineJoin,
        miterLimit: CGFloat,
        dash: [CGFloat],
        dashPhase: CGFloat,
        opacity: Double,
        size: CGSize
    ) -> CIImage? {
        let width: Int = Int(ceil(size.width))
        let height: Int = Int(ceil(size.height))
        guard width > 0, height > 0 else {
            return nil
        }
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context: CGContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        let usesEvenOdd: Bool = fillStyle == FillStyle(eoFill: true)

        let cgPath = path.cgPath
        let hasFill: Bool = fillColor != nil
        let hasStroke: Bool = strokeColor != nil && strokeWidth > 0
        if hasFill {
            if let fillCGColor: CGColor = color(
                from: fillColor,
                opacity: CGFloat(opacity)
            ) {
                context.setFillColor(fillCGColor)
                context.addPath(cgPath)
                context.fillPath(using: usesEvenOdd ? .evenOdd : .winding)
            }
        }
        if hasStroke {
            if let strokeCGColor: CGColor = color(
                from: strokeColor,
                opacity: CGFloat(opacity)
            ) {
                context.setStrokeColor(strokeCGColor)
                context.setLineWidth(CGFloat(strokeWidth))
                context.setLineCap(lineCap)
                context.setLineJoin(lineJoin)
                context.setMiterLimit(miterLimit)
                if !dash.isEmpty {
                    context.setLineDash(phase: dashPhase, lengths: dash)
                }
                context.addPath(cgPath)
                context.strokePath()
            }
        }
        guard let rendered: CGImage = context.makeImage() else {
            return nil
        }
        return CIImage(cgImage: rendered)
    }

    private static func alphaImage(
        from sourceImage: CIImage,
        extent: CGRect
    ) -> CIImage? {
        guard let alphaFilter: CIFilter = CIFilter(name: "CIColorMatrix") else {
            return nil
        }
        let alphaVector = CIVector(
            x: 0,
            y: 0,
            z: 0,
            w: 1
        )
        alphaFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        alphaFilter.setValue(alphaVector, forKey: "inputRVector")
        alphaFilter.setValue(alphaVector, forKey: "inputGVector")
        alphaFilter.setValue(alphaVector, forKey: "inputBVector")
        alphaFilter.setValue(alphaVector, forKey: "inputAVector")
        let output: CIImage? = alphaFilter.outputImage?.cropped(to: extent)
        guard let output else {
            return nil
        }
        return output
    }

    private static func applyPrimitive(
        _ primitive: SVGFilterPrimitive,
                availableSources: [String: CIImage],
                fallbackExtent: CGRect
    ) -> CIImage? {
        switch primitive {
        case .gaussianBlur(let stdDeviationX, let stdDeviationY, let inSource, _):
            let normalizedSourceName: String = normalizedFilterSourceName(inSource, default: sourceGraphicName)
            let source: CIImage = sourceImage(
                name: normalizedSourceName,
                availableSources: availableSources
            )
            let radius: Double = max(stdDeviationX, stdDeviationY)
            let radiusValue: Double = max(radius, 0)
            guard let blurFilter: CIFilter = CIFilter(name: "CIGaussianBlur") else {
                return nil
            }
            blurFilter.setValue(source, forKey: kCIInputImageKey)
            blurFilter.setValue(radiusValue, forKey: kCIInputRadiusKey)
            let filtered: CIImage? = blurFilter.outputImage?.cropped(to: fallbackExtent)
            return filtered
        case .offset(let dx, let dy, let inSource, _):
            let sourceName: String = normalizedFilterSourceName(inSource, default: sourceGraphicName)
            let source: CIImage = sourceImage(
                name: sourceName,
                availableSources: availableSources
            )
            let transform = CGAffineTransform(
                translationX: CGFloat(dx),
                y: CGFloat(dy)
            )
            guard let transformFilter: CIFilter = CIFilter(name: "CIAffineTransform") else {
                return nil
            }
            transformFilter.setValue(source, forKey: kCIInputImageKey)
            transformFilter.setValue(transform, forKey: kCIInputTransformKey)
            return transformFilter.outputImage?.cropped(to: fallbackExtent)
        case .blend(let mode, let inSource, let inSourceTwo, _):
            let firstSourceName: String = normalizedFilterSourceName(inSource, default: sourceGraphicName)
            let secondSourceName: String = normalizedFilterSourceName(inSourceTwo, default: sourceGraphicName)
            let firstSource: CIImage = sourceImage(
                name: firstSourceName,
                availableSources: availableSources
            )
            let secondSource: CIImage = sourceImage(
                name: secondSourceName,
                availableSources: availableSources
            )
            let filterName: String = blendFilterName(for: mode)
            guard let blendFilter: CIFilter = CIFilter(name: filterName) else {
                return nil
            }
            blendFilter.setValue(firstSource, forKey: kCIInputImageKey)
            blendFilter.setValue(secondSource, forKey: kCIInputBackgroundImageKey)
            let filtered: CIImage? = blendFilter.outputImage?.cropped(to: fallbackExtent)
            return filtered
        case .composite(
            let operatorType,
            let inSource,
            let inSourceTwo,
            _, _, _, _,
            _
        ):
            let firstSourceName: String = normalizedFilterSourceName(inSource, default: sourceGraphicName)
            let secondSourceName: String = normalizedFilterSourceName(inSourceTwo, default: sourceGraphicName)
            let firstSource: CIImage = sourceImage(
                name: firstSourceName,
                availableSources: availableSources
            )
            let secondSource: CIImage = sourceImage(
                name: secondSourceName,
                availableSources: availableSources
            )
            let filterName: String = compositeFilterName(for: operatorType)
            guard let compositeFilter: CIFilter = CIFilter(name: filterName) else {
                return nil
            }
            compositeFilter.setValue(firstSource, forKey: kCIInputImageKey)
            compositeFilter.setValue(secondSource, forKey: kCIInputBackgroundImageKey)
            return compositeFilter.outputImage?.cropped(to: fallbackExtent)
        case .colorMatrix(let values, let inSource, _):
            let normalizedSourceName: String = normalizedFilterSourceName(inSource, default: sourceGraphicName)
            let source: CIImage = sourceImage(
                name: normalizedSourceName,
                availableSources: availableSources
            )
            return applyColorMatrix(
                source: source,
                values: values,
                extent: fallbackExtent
            )
        case .unsupported:
            return nil
        }
    }

    private static func fallbackSource(_ availableSources: [String: CIImage]) -> CIImage {
        if let graphic: CIImage = availableSources[sourceGraphicName] {
            return graphic
        }
        if let alpha: CIImage = availableSources[sourceAlphaName] {
            return alpha
        }
        return CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
    }

    private static func normalizedFilterSourceName(
        _ source: String?,
        default defaultName: String
    ) -> String {
        let normalizedSource: String = source?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if normalizedSource.isEmpty {
            return defaultName
        }
        return normalizedSource
    }

    private static func sourceImage(
        name sourceName: String,
        availableSources: [String: CIImage]
    ) -> CIImage {
        if let image = availableSources[sourceName] {
            return image
        }
        if let sourceGraphic: CIImage = availableSources[sourceGraphicName] {
            return sourceGraphic
        }
        if let sourceAlpha: CIImage = availableSources[sourceAlphaName] {
            return sourceAlpha
        }
        return fallbackSource(availableSources)
    }

    private static func blendFilterName(for mode: String) -> String {
        let normalizedMode: String = mode.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalizedMode {
        case "", "normal":
            return "CISourceOverCompositing"
        case "source-over":
            return "CISourceOverCompositing"
        case "multiply":
            return "CIMultiplyBlendMode"
        case "screen":
            return "CIScreenBlendMode"
        case "darken":
            return "CIDarkenBlendMode"
        case "lighten":
            return "CILightenBlendMode"
        case "color-dodge":
            return "CIColorDodgeBlendMode"
        case "color-burn":
            return "CIColorBurnBlendMode"
        case "hard-light":
            return "CIHardLightBlendMode"
        case "soft-light":
            return "CISoftLightBlendMode"
        case "difference":
            return "CIDifferenceBlendMode"
        case "exclusion":
            return "CIExclusionBlendMode"
        case "hue":
            return "CIHueBlendMode"
        case "saturation":
            return "CISaturationBlendMode"
        case "color":
            return "CIColorBlendMode"
        case "luminosity":
            return "CILuminosityBlendMode"
        case "plus":
            return "CIAdditionCompositing"
        default:
            return "CISourceOverCompositing"
        }
    }

    private static func compositeFilterName(for operatorType: String) -> String {
        let normalizedOperator: String = operatorType
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch normalizedOperator {
        case "", "over", "source-over":
            return "CISourceOverCompositing"
        case "in":
            return "CISourceInCompositing"
        case "out":
            return "CISourceOutCompositing"
        case "atop":
            return "CISourceAtopCompositing"
        case "xor":
            return "CIXorCompositing"
        case "lighter":
            return "CIAdditionCompositing"
        case "arithmetic":
            return "CISourceOverCompositing"
        default:
            return "CISourceOverCompositing"
        }
    }

    private static func applyColorMatrix(
        source: CIImage,
        values: [Double],
        extent: CGRect
    ) -> CIImage? {
        let matrixSize: Int = 20
        guard values.count >= matrixSize else {
            return source
        }
        guard let matrixFilter: CIFilter = CIFilter(name: "CIColorMatrix") else {
            return nil
        }
        let rVector = CIVector(
            x: CGFloat(values[0]),
            y: CGFloat(values[1]),
            z: CGFloat(values[2]),
            w: CGFloat(values[3])
        )
        let gVector = CIVector(
            x: CGFloat(values[5]),
            y: CGFloat(values[6]),
            z: CGFloat(values[7]),
            w: CGFloat(values[8])
        )
        let bVector = CIVector(
            x: CGFloat(values[10]),
            y: CGFloat(values[11]),
            z: CGFloat(values[12]),
            w: CGFloat(values[13])
        )
        let aVector = CIVector(
            x: CGFloat(values[15]),
            y: CGFloat(values[16]),
            z: CGFloat(values[17]),
            w: CGFloat(values[18])
        )
        let biasVector = CIVector(
            x: CGFloat(values[4]),
            y: CGFloat(values[9]),
            z: CGFloat(values[14]),
            w: CGFloat(values[19])
        )
        matrixFilter.setValue(source, forKey: kCIInputImageKey)
        matrixFilter.setValue(rVector, forKey: "inputRVector")
        matrixFilter.setValue(gVector, forKey: "inputGVector")
        matrixFilter.setValue(bVector, forKey: "inputBVector")
        matrixFilter.setValue(aVector, forKey: "inputAVector")
        matrixFilter.setValue(biasVector, forKey: "inputBiasVector")
        return matrixFilter.outputImage?.cropped(to: extent)
    }

    private static func color(
        from color: Color?,
        opacity: CGFloat
    ) -> CGColor? {
        guard let color else {
            return nil
        }
        let nativeColor: CGColor? = makeNativeColor(from: color)
        guard let sourceColor: CGColor = nativeColor else {
            return nil
        }
        let sourceAlpha: CGFloat = sourceColor.alpha
        let combinedAlpha: CGFloat = max(0, min(1, opacity)) * sourceAlpha
        return sourceColor.copy(alpha: combinedAlpha)
    }

    private static func makeNativeColor(from color: Color) -> CGColor? {
#if canImport(UIKit)
        let uiColor: UIColor = UIColor(color)
        return uiColor.cgColor
#elseif canImport(AppKit)
        let nsColor: NSColor = NSColor(color)
        return nsColor.cgColor
#else
        return nil
#endif
    }
}
