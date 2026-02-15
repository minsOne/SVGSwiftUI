import CoreGraphics
import Foundation
import XCTest
@testable import SVGSwiftUI

final class SVGClipPathTests: XCTestCase {
    private let parser = SVGParser()
    private let nodePathBuilder = SVGNodePathBuilder()
    private let transformBuilder = SVGTransformBuilder()

    func testClipPathDefinitionBuildsExpectedTransformedGeometry() throws {
        let svg = """
        <svg>
          <clipPath id="window">
            <g transform="translate(5 7)">
              <rect x="10" y="20" width="30" height="40"/>
            </g>
          </clipPath>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="100"
            height="100"
            clip-path="url(#window)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let clipNodes: [SVGNode] = tryUnwrap(document.clipPaths["window"])
        let clipPath = tryUnwrap(buildClipPath(from: clipNodes, inheritedTransform: .identity))
        XCTAssertEqual(clipPath.boundingBoxOfPath, CGRect(x: 15, y: 27, width: 30, height: 40))

        let targetShape: SVGShapeNode = tryUnwrap(shapeNode(id: "foreground", in: document))
        XCTAssertEqual(targetShape.base.attributes["clip-path"], "url(#window)")
    }

    func testClipPathReferenceWithWhitespaceIsStoredWithoutValidation() throws {
        let svg = """
        <svg>
          <defs>
            <clipPath id="spaced">
              <rect x="0" y="0" width="4" height="5"/>
            </clipPath>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            clip-path="url( #spaced )"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertNotNil(document.clipPaths["spaced"])
        XCTAssertNotNil(document.nodes.first)
        XCTAssertEqual(document.nodes.first?.base.attributes["clip-path"], "url( #spaced )")
    }

    func testClipPathReferenceSupportsQuotedURLTokens() throws {
        let svg = """
        <svg>
          <defs>
            <clipPath id="quoted">
              <rect x="0" y="0" width="4" height="5"/>
            </clipPath>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            clip-path='url("#quoted")'
          />
          <rect
            id="foreground-single"
            x="0"
            y="0"
            width="20"
            height="20"
            clip-path="url('#quoted')"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard let first = shapeNode(id: "foreground", in: document) else {
            return XCTFail("Expected first foreground")
        }
        guard let second = shapeNode(id: "foreground-single", in: document) else {
            return XCTFail("Expected second foreground")
        }

        XCTAssertEqual(first.base.attributes["clip-path"], "url(\"#quoted\")")
        XCTAssertEqual(second.base.attributes["clip-path"], "url('#quoted')")
    }

    private func buildClipPath(
        from nodes: [SVGNode],
        inheritedTransform: CGAffineTransform
    ) -> CGPath? {
        let mutablePath = CGMutablePath()
        var hasPath = false

        for node in nodes {
            switch node {
            case .path, .shape:
                if let nodePath = nodePathBuilder.buildPath(for: node, inheritedTransform: inheritedTransform) {
                    mutablePath.addPath(nodePath)
                    hasPath = true
                }
            case .group(let group):
                let nextTransform: CGAffineTransform = transformBuilder.concatenate(
                    local: group.base.transform,
                    inherited: inheritedTransform
                )
                if let groupPath = buildClipPath(
                    from: group.children,
                    inheritedTransform: nextTransform
                ) {
                    mutablePath.addPath(groupPath)
                    hasPath = true
                }
            case .rasterImage:
                break
            }
        }

        if !hasPath {
            return nil
        }
        return mutablePath
    }

    private func shapeNode(id: String, in document: SVGDocument) -> SVGShapeNode? {
        for node in document.nodes {
            if let found = findShapeNode(id: id, in: node) {
                return found
            }
        }
        return nil
    }

    private func findShapeNode(id targetID: String, in node: SVGNode) -> SVGShapeNode? {
        switch node {
        case .group(let group):
            for child in group.children {
                if let found = findShapeNode(id: targetID, in: child) {
                    return found
                }
            }
            return nil
        case .shape(let shape):
            return shape.base.id == targetID ? shape : nil
        case .path, .rasterImage:
            return nil
        }
    }

    private func tryUnwrap<T>(
        _ value: T?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> T {
        guard let value else {
            XCTFail("Expected value", file: file, line: line)
            fatalError("Expected value")
        }
        return value
    }
}
