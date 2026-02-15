import CoreGraphics
import Foundation
import XCTest
@testable import SVGSwiftUI

final class SVGFixtureRegressionTests: XCTestCase {
    private let parser = SVGParser()
    private let resolver = SVGStyleResolver()
    private let nodePathBuilder = SVGNodePathBuilder()
    private let transformBuilder = SVGTransformBuilder()

    func testFixtureSceneTransformsProduceExpectedGeometry() throws {
        let fixture = try fixtureContents(named: "scene_transforms")
        let document = try parser.parse(source: .string(fixture))

        XCTAssertEqual(document.size, SVGSize(width: 120, height: 120))
        XCTAssertEqual(document.nodes.count, 1)

        guard case .group(let panel) = document.nodes.first else {
            return XCTFail("Expected root group node")
        }
        XCTAssertEqual(panel.base.id, "panel")
        XCTAssertEqual(panel.base.transform.operations, [
            .translate(tx: 4, ty: 6),
            .scale(sx: 2, sy: 2),
        ])

        let paths = drawPaths(from: document.nodes, inherited: .identity)
        let rectPath = tryUnwrap(paths["panel-rect"])
        let circlePath = tryUnwrap(paths["nested-circle"])

        assertCGRectEqual(
            rectPath.boundingBoxOfPath,
            CGRect(x: 18.0, y: 22.0, width: 20.0, height: 16.0)
        )
        assertCGRectEqual(
            circlePath.boundingBoxOfPath,
            CGRect(x: 16.0, y: 22.0, width: 12.0, height: 12.0)
        )
    }

    func testFixtureStyleOverridesAndResolverAffectResolvedStyleAndGeometry() throws {
        let fixture = try fixtureContents(named: "style_overrides")
        let document = try parser.parse(source: .string(fixture))

        let configuration = SVGRenderConfiguration(
            idOverrides: [
                "stroke-path": NodeOverride(stroke: .color(.init(red: 0, green: 0, blue: 0, alpha: 1)), strokeWidth: 5),
            ],
            resolver: { context in
                guard context.id == "rect-no-fill" else {
                    return nil
                }
                return NodeOverride(
                    fill: .color(.init(red: 0, green: 1, blue: 0, alpha: 1)),
                    scale: .init(width: 2.0, height: 1.5),
                    offset: .init(x: 1.0, y: -1.0)
                )
            }
        )

        let resolved = resolver.resolve(document: document, configuration: configuration)

        let strokePath: SVGResolvedNodeStyle = tryUnwrap(resolved["stroke-path"])
        let rectOverride: SVGResolvedNodeStyle = tryUnwrap(resolved["rect-no-fill"])
        let standalone: SVGResolvedNodeStyle = tryUnwrap(resolved["standalone-circle"])

        XCTAssertEqual(strokePath.style.fill, SVGPaint.none)
        XCTAssertEqual(strokePath.style.stroke, SVGPaint.color(.init(red: 0, green: 0, blue: 0, alpha: 1)))
        XCTAssertEqual(strokePath.style.strokeWidth, 5)
        XCTAssertEqual(strokePath.style.opacity, 0.6)

        XCTAssertEqual(rectOverride.style.fill, SVGPaint.color(.init(red: 0, green: 1, blue: 0, alpha: 1)))
        XCTAssertEqual(rectOverride.scale, SVGSize(width: 2.0, height: 1.5))
        XCTAssertEqual(rectOverride.offset, SVGPoint(x: 1.0, y: -1.0))

        XCTAssertEqual(standalone.style.fill, SVGPaint.color(.init(red: 0, green: 0, blue: 1, alpha: 1)))
        XCTAssertEqual(standalone.style.opacity, 1.0)

        let paths = drawPaths(from: document.nodes, inherited: .identity)
        let rectPath = tryUnwrap(paths["rect-no-fill"])
        let resizedRectPath = applyGeometryOverrides(
            to: rectPath,
            scale: rectOverride.scale,
            offset: rectOverride.offset
        )

        assertCGRectEqual(
            resizedRectPath.boundingBoxOfPath,
            CGRect(x: 6.0, y: -3.5, width: 20.0, height: 15.0)
        )
    }

    func testFixtureShapeAndPathCommandsMatchExpectedGeometry() throws {
        let fixture = try fixtureContents(named: "shape_commands")
        let document = try parser.parse(source: .string(fixture))

        let pathNode: SVGPathNode = tryUnwrap(pathNode(id: "relative-shape", in: document))
        XCTAssertEqual(
            pathNode.commands.map(\.symbol),
            ["M", "l", "l", "l", "z"]
        )

        let paths = drawPaths(from: document.nodes, inherited: .identity)
        assertCGRectEqual(tryUnwrap(paths["relative-shape"]).boundingBoxOfPath, CGRect(x: 5, y: 5, width: 10, height: 10))
        assertCGRectEqual(tryUnwrap(paths["polyline"]).boundingBoxOfPath, CGRect(x: 0, y: 0, width: 20, height: 10))
        assertCGRectEqual(tryUnwrap(paths["polygon"]).boundingBoxOfPath, CGRect(x: 30, y: -10, width: 20, height: 20))
        assertCGRectEqual(tryUnwrap(paths["line"]).boundingBoxOfPath, CGRect(x: 60, y: 0, width: 10, height: 10))
        assertCGRectEqual(tryUnwrap(paths["ellipse"]).boundingBoxOfPath, CGRect(x: 30, y: 35, width: 20, height: 10))
    }

    private func fixtureContents(named name: String) throws -> String {
        guard let fixtureURL = Bundle.module.url(forResource: name, withExtension: "svg") else {
            throw TestFixtureError.missingFixture(name)
        }
        return try String(contentsOf: fixtureURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func drawPaths(
        from nodes: [SVGNode],
        inherited transform: CGAffineTransform
    ) -> [String: CGPath] {
        var output: [String: CGPath] = [:]

        for node in nodes {
            if let path = nodePathBuilder.buildPath(for: node, inheritedTransform: transform) {
                output[node.nodeID] = path
            }
            if case .group(let group) = node {
                let childTransform: CGAffineTransform = transformBuilder.concatenate(
                    local: group.base.transform,
                    inherited: transform
                )
                let childOutput = drawPaths(from: group.children, inherited: childTransform)
                output.merge(childOutput, uniquingKeysWith: { _, new in new })
            }
        }
        return output
    }

    private func pathNode(id: String, in document: SVGDocument) -> SVGPathNode? {
        for node in document.nodes {
            if let found = findPathNode(id: id, in: node) {
                return found
            }
        }
        return nil
    }

    private func findPathNode(id targetID: String, in node: SVGNode) -> SVGPathNode? {
        switch node {
        case .group(let group):
            for child in group.children {
                if let found = findPathNode(id: targetID, in: child) {
                    return found
                }
            }
            return nil
        case .path(let path):
            return path.base.id == targetID ? path : nil
        case .rasterImage:
            return nil
        case .shape:
            return nil
        }
    }

    private func applyGeometryOverrides(to path: CGPath, scale: SVGSize?, offset: SVGPoint?) -> CGPath {
        var working = path
        if let scale {
            let bounds: CGRect = working.boundingBoxOfPath
            let center: CGPoint = CGPoint(
                x: bounds.midX,
                y: bounds.midY
            )
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: center.x, y: center.y)
            transform = transform.scaledBy(x: CGFloat(scale.width), y: CGFloat(scale.height))
            transform = transform.translatedBy(x: -center.x, y: -center.y)
            working = working.copy(using: &transform) ?? working
        }
        if let offset {
            var offsetTransform = CGAffineTransform(
                translationX: CGFloat(offset.x),
                y: CGFloat(offset.y)
            )
            working = working.copy(using: &offsetTransform) ?? working
        }
        return working
    }

    private func assertCGRectEqual(
        _ lhs: CGRect,
        _ rhs: CGRect,
        accuracy: CGFloat = 0.0001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs.origin.x, rhs.origin.x, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.origin.y, rhs.origin.y, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.size.width, rhs.size.width, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.size.height, rhs.size.height, accuracy: accuracy, file: file, line: line)
    }

    private func tryUnwrap<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) -> T {
        guard let value else {
            XCTFail("Expected value", file: file, line: line)
            fatalError("Expected non-nil value for test assertion")
        }
        return value
    }
}

private enum TestFixtureError: Error {
    case missingFixture(String)
}
