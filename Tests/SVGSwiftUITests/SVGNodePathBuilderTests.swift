import CoreGraphics
import XCTest
@testable import SVGSwiftUI

final class SVGNodePathBuilderTests: XCTestCase {
    private let builder = SVGNodePathBuilder()

    func testBuildsPathNodeFromCommands() {
        let node = SVGNode.path(
            .init(
                base: .init(id: "p", syntheticID: "auto:/0/0"),
                pathData: "M0 0 L10 5",
                commands: [
                    .init(symbol: "M", values: [0, 0]),
                    .init(symbol: "L", values: [10, 5]),
                ]
            )
        )

        let path = builder.buildPath(for: node)
        XCTAssertEqual(path?.boundingBoxOfPath, CGRect(x: 0, y: 0, width: 10, height: 5))
    }

    func testBuildsRectShapePath() {
        let node = SVGNode.shape(
            .init(
                base: .init(id: "rect", syntheticID: "auto:/0/0"),
                kind: .rect,
                values: ["x": 2, "y": 3, "width": 4, "height": 5]
            )
        )

        let path = builder.buildPath(for: node)
        XCTAssertEqual(path?.boundingBoxOfPath, CGRect(x: 2, y: 3, width: 4, height: 5))
    }

    func testBuildsCircleShapePath() {
        let node = SVGNode.shape(
            .init(
                base: .init(id: "circle", syntheticID: "auto:/0/0"),
                kind: .circle,
                values: ["cx": 10, "cy": 20, "r": 4]
            )
        )

        let path = builder.buildPath(for: node)
        XCTAssertEqual(path?.boundingBoxOfPath, CGRect(x: 6, y: 16, width: 8, height: 8))
    }

    func testBuildsPolygonAndClosesSubpath() {
        let node = SVGNode.shape(
            .init(
                base: .init(id: "poly", syntheticID: "auto:/0/0"),
                kind: .polygon,
                points: [
                    .init(x: 0, y: 0),
                    .init(x: 10, y: 0),
                    .init(x: 10, y: 10),
                ]
            )
        )

        let path = builder.buildPath(for: node)
        XCTAssertEqual(path?.boundingBoxOfPath, CGRect(x: 0, y: 0, width: 10, height: 10))
        XCTAssertEqual(path?.elements.last?.type, .closeSubpath)
    }

    func testReturnsNilForGroupNode() {
        let node = SVGNode.group(.init(base: .init(id: "g", syntheticID: "auto:/0/0"), children: []))
        XCTAssertNil(builder.buildPath(for: node))
    }
}

private extension CGPath {
    struct PathElement {
        var type: CGPathElementType
    }

    var elements: [PathElement] {
        var result: [PathElement] = []
        applyWithBlock { elementPointer in
            result.append(PathElement(type: elementPointer.pointee.type))
        }
        return result
    }
}
