import CoreGraphics
import XCTest
@testable import SVGSwiftUI

final class SVGTransformBuilderTests: XCTestCase {
    private let builder = SVGTransformBuilder()

    func testBuildTransformPreservesOperationOrder() {
        let transform = SVGTransform(operations: [
            .translate(tx: 10, ty: 0),
            .scale(sx: 2, sy: 2),
        ])
        let point: CGPoint = CGPoint(x: 1.0, y: 0.0)

        let matrix: CGAffineTransform = builder.makeCGAffineTransform(from: transform)
        let transformed: CGPoint = point.applying(matrix)

        XCTAssertEqual(transformed.x, 22.0, accuracy: 0.0001)
        XCTAssertEqual(transformed.y, 0.0, accuracy: 0.0001)
    }

    func testBuildTransformHandlesRotateAroundCenter() {
        let transform = SVGTransform(operations: [
            .rotate(angleDegrees: 90, cx: 1, cy: 1),
        ])
        let point: CGPoint = CGPoint(x: 2.0, y: 1.0)

        let matrix: CGAffineTransform = builder.makeCGAffineTransform(from: transform)
        let transformed: CGPoint = point.applying(matrix)

        XCTAssertEqual(transformed.x, 1.0, accuracy: 0.0001)
        XCTAssertEqual(transformed.y, 2.0, accuracy: 0.0001)
    }

    func testConcatenateAppliesLocalBeforeInherited() {
        let local = SVGTransform(operations: [
            .translate(tx: 5, ty: 0),
        ])
        let inherited: CGAffineTransform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        let point: CGPoint = CGPoint(x: 1.0, y: 1.0)

        let matrix: CGAffineTransform = builder.concatenate(local: local, inherited: inherited)
        let transformed: CGPoint = point.applying(matrix)

        XCTAssertEqual(transformed.x, 12.0, accuracy: 0.0001)
        XCTAssertEqual(transformed.y, 2.0, accuracy: 0.0001)
    }

    func testBuildSkewXTransform() {
        let transform = SVGTransform(operations: [
            .skewX(angleDegrees: 45),
        ])
        let matrix: CGAffineTransform = builder.makeCGAffineTransform(from: transform)
        let point = CGPoint(x: 1.0, y: 1.0).applying(matrix)

        XCTAssertEqual(point.x, 2.0, accuracy: 0.0001)
        XCTAssertEqual(point.y, 1.0, accuracy: 0.0001)
    }

    func testBuildSkewYTransform() {
        let transform = SVGTransform(operations: [
            .skewY(angleDegrees: 45),
        ])
        let matrix: CGAffineTransform = builder.makeCGAffineTransform(from: transform)
        let point = CGPoint(x: 1.0, y: 1.0).applying(matrix)

        XCTAssertEqual(point.x, 1.0, accuracy: 0.0001)
        XCTAssertEqual(point.y, 2.0, accuracy: 0.0001)
    }
}
