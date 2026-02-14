import XCTest
@testable import SVGSwiftUI

final class SVGParserTests: XCTestCase {
    private let parser = SVGParser()

    func testParseRejectsEmptyInput() {
        XCTAssertThrowsError(try parser.parse(source: .string(""))) { error in
            XCTAssertEqual(error as? SVGParserError, .emptyInput)
        }
    }

    func testParseRejectsNonSVGRoot() {
        XCTAssertThrowsError(try parser.parse(source: .string("<html></html>"))) { error in
            XCTAssertEqual(error as? SVGParserError, .invalidSVGRoot)
        }
    }

    func testParseThrowsMalformedDocumentForBrokenXML() {
        XCTAssertThrowsError(try parser.parse(source: .string("<svg><g></svg>"))) { error in
            guard case .malformedDocument = (error as? SVGParserError) else {
                return XCTFail("Expected malformedDocument, got \(error)")
            }
        }
    }

    func testParseReadsRootSizeAndViewBox() throws {
        let document = try parser.parse(source: .string("<svg width='24' height='32' viewBox='0 0 24 32'></svg>"))

        XCTAssertEqual(document.size, SVGSize(width: 24, height: 32))
        XCTAssertEqual(document.viewBox, SVGRect(x: 0, y: 0, width: 24, height: 32))
    }

    func testParseSetsRootSizeNilForPercentageUnits() throws {
        let document = try parser.parse(source: .string("<svg width='100%' height='100%'></svg>"))
        XCTAssertNil(document.size)
    }

    func testParseHandlesNamespacePrefixedElements() throws {
        let svg = """
        <svg xmlns:foo="http://example.com/svg">
          <foo:g id="grp">
            <foo:path id="prefixed-path" d="M0 0"/>
          </foo:g>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertEqual(document.nodes.count, 1)

        guard case .group(let group) = document.nodes[0] else {
            return XCTFail("Expected group node")
        }
        XCTAssertEqual(group.base.id, "grp")
        XCTAssertEqual(group.children.count, 1)
        XCTAssertEqual(pathNode(id: "prefixed-path", in: document)?.pathData, "M0 0")
    }

    func testParseIgnoresUnsupportedElementsButKeepsSupportedSiblings() throws {
        let svg = """
        <svg width="20" height="20">
          <defs>
            <path id="inside-defs" d="M0 0 L5 5"/>
          </defs>
          <circle id="kept-circle" cx="5" cy="5" r="2"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertNil(pathNode(id: "inside-defs", in: document))

        guard let circle = shapeNode(id: "kept-circle", in: document) else {
            return XCTFail("Expected circle shape")
        }
        XCTAssertEqual(circle.kind, .circle)
    }

    func testParseIgnoresNestedSVGSubtrees() throws {
        let svg = """
        <svg>
          <svg>
            <path id="nested-path" d="M0 0"/>
          </svg>
          <path id="top-path" d="M1 1"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertNil(pathNode(id: "nested-path", in: document))
        XCTAssertEqual(pathNode(id: "top-path", in: document)?.pathData, "M1 1")
    }

    func testParseBuildsTreeForGroupPathAndRect() throws {
        let svg = """
        <svg width="100" height="100">
          <g id="icon-group" transform="translate(4 8)">
            <path id="main-path" d="M0 0 L10 10" fill="#ff0000"/>
            <rect id="box" x="1" y="2" width="3" height="4" />
          </g>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))

        XCTAssertEqual(document.nodes.count, 1)
        guard case .group(let group) = document.nodes[0] else {
            return XCTFail("Expected group node")
        }
        XCTAssertEqual(group.base.id, "icon-group")
        XCTAssertEqual(group.base.transform.operations.count, 1)
        XCTAssertEqual(group.children.count, 2)

        guard case .path(let pathNode) = group.children[0] else {
            return XCTFail("Expected path node")
        }
        XCTAssertEqual(pathNode.base.id, "main-path")
        XCTAssertEqual(pathNode.pathData, "M0 0 L10 10")
        XCTAssertEqual(pathNode.commands, [
            .init(symbol: "M", values: [0, 0]),
            .init(symbol: "L", values: [10, 10]),
        ])

        guard case .shape(let rectNode) = group.children[1] else {
            return XCTFail("Expected shape node")
        }
        XCTAssertEqual(rectNode.kind, .rect)
        XCTAssertEqual(rectNode.values["x"], 1)
        XCTAssertEqual(rectNode.values["y"], 2)
        XCTAssertEqual(rectNode.values["width"], 3)
        XCTAssertEqual(rectNode.values["height"], 4)
    }

    func testParseGeneratesDeterministicSyntheticIDs() throws {
        let svg = """
        <svg>
          <g>
            <path/>
            <rect/>
          </g>
          <circle/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))

        guard case .group(let group) = document.nodes[0] else {
            return XCTFail("Expected first root node as group")
        }
        XCTAssertEqual(group.base.syntheticID, "auto:/0/0")

        guard case .path(let path) = group.children[0] else {
            return XCTFail("Expected first child path")
        }
        XCTAssertEqual(path.base.syntheticID, "auto:/0/0/0")

        guard case .shape(let rect) = group.children[1] else {
            return XCTFail("Expected second child rect")
        }
        XCTAssertEqual(rect.base.syntheticID, "auto:/0/0/1")

        guard case .shape(let circle) = document.nodes[1] else {
            return XCTFail("Expected second root node circle")
        }
        XCTAssertEqual(circle.base.syntheticID, "auto:/0/1")
    }

    func testInlineStyleOverridesPresentationAttributes() throws {
        let svg = """
        <svg width="24" height="24">
          <path d="M0 0 L1 1" fill="black" style="fill:#00ff00;stroke:#0000ff;stroke-width:2;opacity:0.5"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard case .path(let path) = document.nodes.first else {
            return XCTFail("Expected path node")
        }
        XCTAssertEqual(path.base.style.fill, .color(.init(red: 0, green: 1, blue: 0, alpha: 1)))
        XCTAssertEqual(path.base.style.stroke, .color(.init(red: 0, green: 0, blue: 1, alpha: 1)))
        XCTAssertEqual(path.base.style.strokeWidth, 2)
        XCTAssertEqual(path.base.style.opacity, 0.5)
    }

    func testParseSupportsMultiplePaintFormats() throws {
        let svg = """
        <svg>
          <path id="hex3" d="M0 0" fill="#0f0"/>
          <path id="rgb" d="M0 0" fill="rgb(255, 0, 0)"/>
          <path id="named" d="M0 0" fill="blue"/>
          <path id="none" d="M0 0" fill="none"/>
          <path id="current" d="M0 0" fill="currentColor"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertEqual(pathNode(id: "hex3", in: document)?.base.style.fill, .color(.init(red: 0, green: 1, blue: 0, alpha: 1)))
        XCTAssertEqual(pathNode(id: "rgb", in: document)?.base.style.fill, .color(.init(red: 1, green: 0, blue: 0, alpha: 1)))
        XCTAssertEqual(pathNode(id: "named", in: document)?.base.style.fill, .color(.init(red: 0, green: 0, blue: 1, alpha: 1)))
        XCTAssertEqual(pathNode(id: "none", in: document)?.base.style.fill, SVGPaint.none)
        XCTAssertEqual(pathNode(id: "current", in: document)?.base.style.fill, .currentColor)
    }

    func testParseTransformOperationsInOrder() throws {
        let svg = """
        <svg>
          <path id="t" d="M0 0" transform="translate(10,20) scale(2) rotate(90 1 2) matrix(1 0 0 1 3 4)"/>
        </svg>
        """
        let document = try parser.parse(source: .string(svg))
        let operations = pathNode(id: "t", in: document)?.base.transform.operations

        XCTAssertEqual(operations, [
            .translate(tx: 10, ty: 20),
            .scale(sx: 2, sy: 2),
            .rotate(angleDegrees: 90, cx: 1, cy: 2),
            .matrix(a: 1, b: 0, c: 0, d: 1, tx: 3, ty: 4),
        ])
    }

    func testParsePathWithoutDUsesEmptyString() throws {
        let document = try parser.parse(source: .string("<svg><path id='empty'/></svg>"))
        XCTAssertEqual(pathNode(id: "empty", in: document)?.pathData, "")
        XCTAssertEqual(pathNode(id: "empty", in: document)?.commands, [])
    }

    func testParseThrowsMalformedDocumentForInvalidPathData() {
        let svg = "<svg><path d='R 10 10'/></svg>"
        XCTAssertThrowsError(try parser.parse(source: .string(svg))) { error in
            guard case .malformedDocument = (error as? SVGParserError) else {
                return XCTFail("Expected malformedDocument, got \(error)")
            }
        }
    }

    func testParseNumericAcceptsPxValuesForShapeAttributes() throws {
        let document = try parser.parse(source: .string("<svg><rect id='r' x='1px' y='2px' width='3px' height='4px'/></svg>"))
        guard let rect = shapeNode(id: "r", in: document) else {
            return XCTFail("Expected rect node")
        }
        XCTAssertEqual(rect.values["x"], 1)
        XCTAssertEqual(rect.values["y"], 2)
        XCTAssertEqual(rect.values["width"], 3)
        XCTAssertEqual(rect.values["height"], 4)
    }

    func testParsePolylinePoints() throws {
        let svg = """
        <svg width="24" height="24">
          <polyline points="0,0 10,10 20,5"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard case .shape(let polyline) = document.nodes.first else {
            return XCTFail("Expected polyline node")
        }
        XCTAssertEqual(polyline.kind, .polyline)
        XCTAssertEqual(polyline.points, [
            .init(x: 0, y: 0),
            .init(x: 10, y: 10),
            .init(x: 20, y: 5),
        ])
    }

    func testParsePolygonDropsTrailingOddCoordinate() throws {
        let svg = """
        <svg width="24" height="24">
          <polygon id="pg" points="0,0 10,10 20"/>
        </svg>
        """
        let document = try parser.parse(source: .string(svg))
        guard let polygon = shapeNode(id: "pg", in: document) else {
            return XCTFail("Expected polygon node")
        }
        XCTAssertEqual(polygon.points, [
            .init(x: 0, y: 0),
            .init(x: 10, y: 10),
        ])
    }

    private func allNodes(in document: SVGDocument) -> [SVGNode] {
        flatten(document.nodes)
    }

    private func flatten(_ nodes: [SVGNode]) -> [SVGNode] {
        var output: [SVGNode] = []
        for node in nodes {
            output.append(node)
            if case .group(let group) = node {
                output.append(contentsOf: flatten(group.children))
            }
        }
        return output
    }

    private func pathNode(id: String, in document: SVGDocument) -> SVGPathNode? {
        for node in allNodes(in: document) {
            if case .path(let path) = node, path.base.id == id {
                return path
            }
        }
        return nil
    }

    private func shapeNode(id: String, in document: SVGDocument) -> SVGShapeNode? {
        for node in allNodes(in: document) {
            if case .shape(let shape) = node, shape.base.id == id {
                return shape
            }
        }
        return nil
    }
}
