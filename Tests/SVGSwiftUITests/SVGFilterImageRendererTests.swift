import CoreGraphics
import Foundation
import SwiftUI
import XCTest
@testable import SVGSwiftUI

final class SVGFilterImageRendererTests: XCTestCase {
    func testRenderFilteredImageAppliesIdentityColorMatrix() throws {
        let sourceColor: Color = Color(red: 1, green: 0, blue: 0, opacity: 1)
        let identityMatrix: [Double] = [
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0
        ]
        let imageSize: CGSize = CGSize(width: 20, height: 20)
        guard let renderedImage = SVGFilterImageRenderer.renderFilteredImage(
            path: Path(CGRect(origin: .zero, size: imageSize)),
            fillColor: sourceColor,
            fillStyle: FillStyle(eoFill: false),
            strokeColor: nil,
            strokeWidth: 0,
            lineCap: .round,
            lineJoin: .miter,
            miterLimit: 10,
            dash: [],
            dashPhase: 0,
            opacity: 1.0,
            size: imageSize,
            primitives: [
                .colorMatrix(
                    values: identityMatrix,
                    inSource: "SourceGraphic",
                    result: nil
                )
            ]
        ) else {
            XCTFail("Expected rendered image")
            return
        }

        let center = CGPoint(x: 10, y: 10)
        guard let pixel = pixel(from: renderedImage, at: center) else {
            XCTFail("Expected non-nil pixel")
            return
        }
        XCTAssertGreaterThan(pixel.r, 240)
        XCTAssertLessThan(pixel.g, 15)
        XCTAssertLessThan(pixel.b, 15)
        XCTAssertEqual(pixel.a, 255)
    }

    func testRenderFilteredImageAppliesBlendMultiply() throws {
        let sourceColor: Color = Color(red: 1, green: 0, blue: 0, opacity: 1)
        let imageSize: CGSize = CGSize(width: 16, height: 16)
        guard let renderedImage = SVGFilterImageRenderer.renderFilteredImage(
            path: Path(CGRect(origin: .zero, size: imageSize)),
            fillColor: sourceColor,
            fillStyle: FillStyle(eoFill: false),
            strokeColor: nil,
            strokeWidth: 0,
            lineCap: .round,
            lineJoin: .miter,
            miterLimit: 10,
            dash: [],
            dashPhase: 0,
            opacity: 1.0,
            size: imageSize,
            primitives: [.blend(mode: "multiply", inSource: nil, inSourceTwo: nil, result: nil)]
        ) else {
            XCTFail("Expected rendered image")
            return
        }

        let center = CGPoint(x: 8, y: 8)
        guard let pixel = pixel(from: renderedImage, at: center) else {
            XCTFail("Expected non-nil pixel")
            return
        }
        XCTAssertGreaterThan(pixel.r, 240)
        XCTAssertLessThan(pixel.g, 20)
        XCTAssertLessThan(pixel.b, 20)
        XCTAssertEqual(pixel.a, 255)
    }

    func testRenderFilteredImageResolvesResultInChain() {
        let sourceColor: Color = Color(red: 1, green: 0, blue: 0, opacity: 1)
        let imageSize: CGSize = CGSize(width: 50, height: 50)
        let toGreenMatrix: [Double] = [
            0, 0, 0, 0, 0,
            1, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            0, 0, 0, 1, 0
        ]
        guard let renderedImage = SVGFilterImageRenderer.renderFilteredImage(
            path: Path(CGRect(origin: .zero, size: imageSize)),
            fillColor: sourceColor,
            fillStyle: FillStyle(eoFill: false),
            strokeColor: nil,
            strokeWidth: 0,
            lineCap: .round,
            lineJoin: .miter,
            miterLimit: 10,
            dash: [],
            dashPhase: 0,
            opacity: 1.0,
            size: imageSize,
            primitives: [
                .offset(dx: 20, dy: 0, inSource: "SourceGraphic", result: "shifted"),
                .colorMatrix(values: toGreenMatrix, inSource: "shifted", result: nil)
            ]
        ) else {
            XCTFail("Expected rendered image")
            return
        }

        let center = CGPoint(x: 25, y: 25)
        guard let pixel = pixel(from: renderedImage, at: center) else {
            XCTFail("Expected non-nil pixel")
            return
        }
        XCTAssertGreaterThan(pixel.g, 200)
        XCTAssertLessThan(pixel.r, 40)
        XCTAssertLessThan(pixel.b, 40)
    }

    func testRenderFilteredImageBlendsWithChainedSource() {
        let sourceColor: Color = Color(red: 1, green: 0, blue: 0, opacity: 1)
        let imageSize: CGSize = CGSize(width: 50, height: 50)
        let toGreenMatrix: [Double] = [
            0, 0, 0, 0, 0,
            1, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            0, 0, 0, 1, 0
        ]
        guard let renderedImage = SVGFilterImageRenderer.renderFilteredImage(
            path: Path(CGRect(origin: .zero, size: imageSize)),
            fillColor: sourceColor,
            fillStyle: FillStyle(eoFill: false),
            strokeColor: nil,
            strokeWidth: 0,
            lineCap: .round,
            lineJoin: .miter,
            miterLimit: 10,
            dash: [],
            dashPhase: 0,
            opacity: 1.0,
            size: imageSize,
            primitives: [
                .offset(dx: 20, dy: 0, inSource: "SourceGraphic", result: "shifted"),
                .colorMatrix(values: toGreenMatrix, inSource: "shifted", result: "greenShifted"),
                .blend(mode: "screen", inSource: "greenShifted", inSourceTwo: "SourceGraphic", result: nil)
            ]
        ) else {
            XCTFail("Expected rendered image")
            return
        }

        let center = CGPoint(x: 25, y: 25)
        guard let pixel = pixel(from: renderedImage, at: center) else {
            XCTFail("Expected non-nil pixel")
            return
        }
        XCTAssertGreaterThan(pixel.r, 150)
        XCTAssertGreaterThan(pixel.g, 150)
        XCTAssertLessThan(pixel.b, 60)
    }

    func testRequiresOffscreenProcessingForBlendAndMatrixOnly() {
        XCTAssertTrue(
            SVGFilterImageRenderer.requiresOffscreenProcessing(
                [.blend(mode: "multiply", inSource: "SourceGraphic", inSourceTwo: "SourceGraphic", result: nil)]
            )
        )
        XCTAssertTrue(
            SVGFilterImageRenderer.requiresOffscreenProcessing(
                [.colorMatrix(values: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0], inSource: "SourceGraphic", result: nil)]
            )
        )
        XCTAssertFalse(
            SVGFilterImageRenderer.requiresOffscreenProcessing(
                [.gaussianBlur(stdDeviationX: 2, stdDeviationY: 2, inSource: "SourceGraphic", result: nil)]
            )
        )
    }

    private func pixel(
        from image: CGImage,
        at point: CGPoint
    ) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8)? {
        guard let dataRef = image.dataProvider?.data else {
            return nil
        }
        guard let dataPtr = CFDataGetBytePtr(dataRef) else {
            return nil
        }
        let px: Int = Int(point.x)
        let py: Int = Int(point.y)
        guard px >= 0, py >= 0, px < image.width, py < image.height else {
            return nil
        }
        let bytesPerPixel: Int = 4
        let index: Int = py * image.bytesPerRow + px * bytesPerPixel
        let red: UInt8 = dataPtr[index]
        let green: UInt8 = dataPtr[index + 1]
        let blue: UInt8 = dataPtr[index + 2]
        let alpha: UInt8 = dataPtr[index + 3]
        return (r: red, g: green, b: blue, a: alpha)
    }
}
