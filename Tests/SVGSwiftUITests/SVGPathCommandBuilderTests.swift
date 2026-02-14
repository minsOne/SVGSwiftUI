import CoreGraphics
import XCTest
@testable import SVGSwiftUI

final class SVGPathCommandBuilderTests: XCTestCase {
    private let builder = SVGPathCommandBuilder()

    func testBuildsMoveLineCloseElements() {
        let commands: [SVGPathCommand] = [
            .init(symbol: "M", values: [0, 0]),
            .init(symbol: "L", values: [10, 20]),
            .init(symbol: "Z", values: []),
        ]

        let path = builder.buildPath(commands: commands)
        let elements = path.elements

        XCTAssertEqual(elements.map(\.type), [.moveToPoint, .addLineToPoint, .closeSubpath])
        XCTAssertEqual(elements[1].points.first, CGPoint(x: 10, y: 20))
    }

    func testBuildsRelativeHorizontalVerticalCommands() {
        let commands: [SVGPathCommand] = [
            .init(symbol: "M", values: [5, 5]),
            .init(symbol: "h", values: [10]),
            .init(symbol: "v", values: [-3]),
        ]

        let path = builder.buildPath(commands: commands)
        let elements = path.elements

        XCTAssertEqual(elements.count, 3)
        XCTAssertEqual(elements[1].points.first, CGPoint(x: 15, y: 5))
        XCTAssertEqual(elements[2].points.first, CGPoint(x: 15, y: 2))
    }

    func testBuildsSmoothCubicCommand() {
        let commands: [SVGPathCommand] = [
            .init(symbol: "M", values: [0, 0]),
            .init(symbol: "C", values: [10, 0, 20, 10, 30, 10]),
            .init(symbol: "S", values: [40, 20, 50, 10]),
        ]

        let path = builder.buildPath(commands: commands)
        let elements = path.elements

        XCTAssertEqual(elements.map(\.type), [.moveToPoint, .addCurveToPoint, .addCurveToPoint])
        XCTAssertEqual(elements[2].points.last, CGPoint(x: 50, y: 10))
        XCTAssertEqual(elements[2].points[0], CGPoint(x: 40, y: 10))
    }

    func testBuildsSmoothQuadraticCommand() {
        let commands: [SVGPathCommand] = [
            .init(symbol: "M", values: [0, 0]),
            .init(symbol: "Q", values: [10, 0, 20, 10]),
            .init(symbol: "T", values: [40, 10]),
        ]

        let path = builder.buildPath(commands: commands)
        let elements = path.elements

        XCTAssertEqual(elements.map(\.type), [.moveToPoint, .addQuadCurveToPoint, .addQuadCurveToPoint])
        XCTAssertEqual(elements[2].points.last, CGPoint(x: 40, y: 10))
    }

    func testBuildsArcCommandEndingAtExpectedPoint() {
        let commands: [SVGPathCommand] = [
            .init(symbol: "M", values: [0, 0]),
            .init(symbol: "A", values: [10, 10, 0, 0, 1, 20, 0]),
        ]

        let path = builder.buildPath(commands: commands)
        let elements = path.elements
        guard let last = elements.last?.points.last else {
            return XCTFail("Expected arc to create curve elements")
        }
        XCTAssertEqual(last.x, 20, accuracy: 0.001)
        XCTAssertEqual(last.y, 0, accuracy: 0.001)
    }
}

private extension CGPath {
    struct PathElement {
        var type: CGPathElementType
        var points: [CGPoint]
    }

    var elements: [PathElement] {
        var result: [PathElement] = []
        applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            let points: [CGPoint]
            switch element.type {
            case .moveToPoint, .addLineToPoint:
                points = [element.points[0]]
            case .addQuadCurveToPoint:
                points = [element.points[0], element.points[1]]
            case .addCurveToPoint:
                points = [element.points[0], element.points[1], element.points[2]]
            case .closeSubpath:
                points = []
            @unknown default:
                points = []
            }
            result.append(PathElement(type: element.type, points: points))
        }
        return result
    }
}
