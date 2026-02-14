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

    func testParseReadsRootSizeAndViewBox() throws {
        let document = try parser.parse(source: .string("<svg width='24' height='32' viewBox='0 0 24 32'></svg>"))

        XCTAssertEqual(document.size, SVGSize(width: 24, height: 32))
        XCTAssertEqual(document.viewBox, SVGRect(x: 0, y: 0, width: 24, height: 32))
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

        guard case .shape(let rectNode) = group.children[1] else {
            return XCTFail("Expected shape node")
        }
        XCTAssertEqual(rectNode.kind, .rect)
        XCTAssertEqual(rectNode.values["x"], 1)
        XCTAssertEqual(rectNode.values["y"], 2)
        XCTAssertEqual(rectNode.values["width"], 3)
        XCTAssertEqual(rectNode.values["height"], 4)
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
}
